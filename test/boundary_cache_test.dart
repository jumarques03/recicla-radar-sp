import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/data/local/boundary_cache.dart';
import 'package:recicla_radar_sp/data/models/city_boundaries.dart';
import 'package:recicla_radar_sp/data/osm/cached_boundary_repository.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';

CityBoundaries sample() => CityBoundaries(
  city: [
    GeoPolygon(
      const [LatLng(-23.5, -46.7), LatLng(-23.5, -46.6), LatLng(-23.6, -46.6)],
      const [
        [LatLng(-23.52, -46.66), LatLng(-23.52, -46.64), LatLng(-23.54, -46.64)],
      ],
    ),
  ],
  districts: {
    '10': DistrictShape(
      id: '10',
      name: 'Sé',
      polygons: [
        GeoPolygon(const [LatLng(-23.55, -46.64), LatLng(-23.55, -46.63), LatLng(-23.56, -46.63)]),
      ],
    ),
  },
);

class _Source implements BoundaryRepository {
  _Source({this.fails = false});

  bool fails;
  int calls = 0;

  @override
  Future<CityBoundaries> fetchBoundaries() async {
    calls++;
    if (fails) throw const AppException('sem internet');
    return sample();
  }
}

class _MemoryCache implements BoundaryCache {
  CityBoundaries? saved;

  @override
  Future<CityBoundaries?> read() async => saved;

  @override
  Future<void> write(CityBoundaries boundaries) async => saved = boundaries;
}

void main() {
  group('BoundariesCodec', () {
    test('guarda e devolve os mesmos limites, com buracos e nomes', () {
      final decoded = BoundariesCodec.decode(BoundariesCodec.encode(sample()))!;

      expect(decoded.city.single.outer, sample().city.single.outer);
      expect(decoded.city.single.holes.single, sample().city.single.holes.single);
      expect(decoded.districts['10']!.name, 'Sé');
      expect(decoded.districts['10']!.polygons.single.outer.length, 3);
    });

    test('arredonda para 5 casas decimais (cerca de 1 metro)', () {
      final precise = CityBoundaries(
        city: [GeoPolygon(const [LatLng(-23.123456789, -46.987654321)])],
        districts: const {},
      );
      final point = BoundariesCodec.decode(BoundariesCodec.encode(precise))!.city.single.outer.single;
      expect(point.latitude, -23.12346);
      expect(point.longitude, -46.98765);
    });

    test('formato inesperado vira null em vez de quebrar', () {
      expect(BoundariesCodec.decode({'city': 'x'}), isNull);
      expect(BoundariesCodec.decode(null), isNull);
    });
  });

  group('FileBoundaryCache', () {
    late Directory dir;

    setUp(() => dir = Directory.systemTemp.createTempSync('boundary_cache_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('o que foi gravado continua lá depois de "fechar e abrir" o app', () async {
      await FileBoundaryCache(directory: () async => dir).write(sample());

      // Outro objeto sobre o mesmo arquivo, como num app reaberto.
      final reopened = await FileBoundaryCache(directory: () async => dir).read();
      expect(reopened!.districts.keys, ['10']);
      expect(File('${dir.path}/${FileBoundaryCache.fileName}.tmp').existsSync(), isFalse);
    });

    test('sem arquivo devolve null; arquivo estragado também', () async {
      final cache = FileBoundaryCache(directory: () async => dir);
      expect(await cache.read(), isNull);

      File('${dir.path}/${FileBoundaryCache.fileName}').writeAsStringSync('{ não é json');
      expect(await cache.read(), isNull);
    });

    test('pasta indisponível não derruba o app', () async {
      final cache = FileBoundaryCache(directory: () async => throw const FileSystemException('sem acesso'));
      await cache.write(sample());
      expect(await cache.read(), isNull);
    });
  });

  group('CachedBoundaryRepository', () {
    test('só vai à internet na primeira vez; depois usa o que está guardado', () async {
      final source = _Source();
      final cache = _MemoryCache();

      await CachedBoundaryRepository(source: source, cache: cache).fetchBoundaries();
      expect(source.calls, 1);
      expect(cache.saved, isNotNull);

      // App reaberto, agora sem internet: o mapa ainda tem os distritos.
      final offline = _Source(fails: true);
      final boundaries = await CachedBoundaryRepository(source: offline, cache: cache).fetchBoundaries();
      expect(offline.calls, 0);
      expect(boundaries.districts.keys, ['10']);
    });

    test('sem cache e sem internet, o erro chega à tela (que mostra "Tentar de novo")', () async {
      final repository = CachedBoundaryRepository(source: _Source(fails: true), cache: _MemoryCache());
      await expectLater(repository.fetchBoundaries(), throwsA(isA<AppException>()));
    });
  });
}
