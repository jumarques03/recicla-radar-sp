import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:recicla_radar_sp/core/utils/app_exception.dart';
import 'package:recicla_radar_sp/data/osm/osm_boundary_repository.dart';

const int cityId = 298285;

/// Responde como o Nominatim: um GeoJSON com um quadrado para cada id pedido.
http.Response nominatimResponse(http.Request request) {
  final ids = request.url.queryParameters['osm_ids']!.split(',').map((r) => int.parse(r.substring(1)));
  final features = [
    for (final id in ids)
      {
        'type': 'Feature',
        'properties': {'osm_id': id, 'name': id == cityId ? 'São Paulo' : 'Distrito $id'},
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-46.7, -23.6],
              [-46.6, -23.6],
              [-46.6, -23.5],
              [-46.7, -23.6],
            ],
          ],
        },
      },
  ];
  return http.Response.bytes(
    utf8.encode(jsonEncode({'type': 'FeatureCollection', 'features': features})),
    200,
  );
}

void main() {
  test('busca o município e os distritos em lotes de no máximo 50 ids', () async {
    final requests = <http.Request>[];
    final repository = OsmBoundaryRepository(
      districtIds: [for (var i = 1; i <= 96; i++) i],
      pauseBetweenRequests: Duration.zero,
      client: MockClient((request) async {
        requests.add(request);
        return nominatimResponse(request);
      }),
    );

    final boundaries = await repository.fetchBoundaries();

    // 1 município + 96 distritos = 97 ids, em 2 requisições.
    expect(requests, hasLength(2));
    expect(requests.first.url.host, 'nominatim.openstreetmap.org');
    expect(requests.first.url.queryParameters['osm_ids']!.split(',').first, 'R$cityId');
    expect(requests.every((r) => r.url.queryParameters['osm_ids']!.split(',').length <= 50), isTrue);
    expect(requests.first.headers['User-Agent'], contains('ReciclaRadarSP'));

    expect(boundaries.city, hasLength(1));
    expect(boundaries.districts, hasLength(96));
    expect(boundaries.districts['7']!.name, 'Distrito 7');
  });

  test('erro do servidor vira mensagem clara', () async {
    final repository = OsmBoundaryRepository(
      districtIds: const [1, 2],
      pauseBetweenRequests: Duration.zero,
      client: MockClient((request) async => http.Response('erro', 500)),
    );

    expect(
      repository.fetchBoundaries(),
      throwsA(isA<AppException>().having((e) => e.message, 'message', contains('internet'))),
    );
  });

  test('falta de internet também vira mensagem clara', () async {
    final repository = OsmBoundaryRepository(
      districtIds: const [1],
      pauseBetweenRequests: Duration.zero,
      client: MockClient((request) async => throw http.ClientException('sem rede')),
    );

    expect(repository.fetchBoundaries(), throwsA(isA<AppException>()));
  });
}
