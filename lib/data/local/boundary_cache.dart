import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';
import 'package:path_provider/path_provider.dart';

import 'package:recicla_radar_sp/data/models/city_boundaries.dart';

/// Guarda no aparelho o contorno da cidade e dos distritos, para o mapa continuar
/// mostrando os distritos sem internet.
abstract interface class BoundaryCache {
  /// Devolve o que foi guardado, ou `null` se não há nada (ou se o arquivo está estragado).
  Future<CityBoundaries?> read();

  Future<void> write(CityBoundaries boundaries);
}

/// Guarda em um arquivo JSON na pasta de dados do app.
///
/// Não funciona no navegador (não há arquivos); nesse caso simplesmente não guarda.
class FileBoundaryCache implements BoundaryCache {
  FileBoundaryCache({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  /// O sufixo de versão permite mudar o formato sem quebrar quem já tem o arquivo.
  static const String fileName = 'boundaries.v1.json';

  final Future<Directory> Function() _directory;

  Future<File> _file() async => File('${(await _directory()).path}/$fileName');

  @override
  Future<CityBoundaries?> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return null;
      final boundaries = BoundariesCodec.decode(
        jsonDecode(await file.readAsString()),
      );
      return boundaries == null || boundaries.isEmpty ? null : boundaries;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(CityBoundaries boundaries) async {
    try {
      final file = await _file();
      await file.parent.create(recursive: true);
      // Grava num arquivo temporário e renomeia, para nunca ficar um arquivo pela metade.
      final temp = File('${file.path}.tmp');
      await temp.writeAsString(
        jsonEncode(BoundariesCodec.encode(boundaries)),
        flush: true,
      );
      await temp.rename(file.path);
    } catch (_) {
      // Sem cache o app continua funcionando; só precisa de internet na próxima vez.
    }
  }
}

/// Converte os limites de e para JSON. Coordenadas com 5 casas decimais (cerca de
/// 1 m), o que basta para desenhar e deixa o arquivo bem menor.
abstract final class BoundariesCodec {
  static Map<String, Object?> encode(CityBoundaries boundaries) => {
    'city': [for (final polygon in boundaries.city) _encodePolygon(polygon)],
    'districts': {
      for (final entry in boundaries.districts.entries)
        entry.key: {
          'name': entry.value.name,
          'polygons': [
            for (final polygon in entry.value.polygons) _encodePolygon(polygon),
          ],
        },
    },
  };

  /// Devolve `null` se o JSON não tem o formato esperado.
  static CityBoundaries? decode(Object? json) {
    try {
      final map = json as Map<String, dynamic>;
      final districts = <String, DistrictShape>{};
      (map['districts'] as Map<String, dynamic>).forEach((id, value) {
        final item = value as Map<String, dynamic>;
        districts[id] = DistrictShape(
          id: id,
          name: item['name'] as String,
          polygons: [
            for (final p in item['polygons'] as List) _decodePolygon(p),
          ],
        );
      });
      return CityBoundaries(
        city: [for (final p in map['city'] as List) _decodePolygon(p)],
        districts: districts,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, Object?> _encodePolygon(GeoPolygon polygon) => {
    'o': _encodeRing(polygon.outer),
    if (polygon.holes.isNotEmpty)
      'h': [for (final hole in polygon.holes) _encodeRing(hole)],
  };

  static GeoPolygon _decodePolygon(Object? json) {
    final map = json as Map<String, dynamic>;
    return GeoPolygon(_decodeRing(map['o'] as List), [
      for (final hole in (map['h'] as List? ?? const []))
        _decodeRing(hole as List),
    ]);
  }

  static List<List<double>> _encodeRing(List<LatLng> ring) => [
    for (final point in ring) [_round(point.latitude), _round(point.longitude)],
  ];

  static List<LatLng> _decodeRing(List ring) => [
    for (final point in ring)
      LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble()),
  ];

  static double _round(double value) =>
      (value * 100000).roundToDouble() / 100000;
}
