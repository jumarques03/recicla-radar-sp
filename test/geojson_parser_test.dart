import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/data/osm/geojson_parser.dart';

Map<String, dynamic> feature(int osmId, String name, Map<String, dynamic> geometry) => {
      'type': 'Feature',
      'properties': {'osm_id': osmId, 'name': name},
      'geometry': geometry,
    };

void main() {
  test('lê um Polygon e troca a ordem [lng, lat] para (lat, lng)', () {
    final features = GeoJsonParser.parseFeatures({
      'features': [
        feature(10, 'Sé', {
          'type': 'Polygon',
          'coordinates': [
            [
              [-46.64, -23.55],
              [-46.63, -23.55],
              [-46.63, -23.54],
              [-46.64, -23.55],
            ],
          ],
        }),
      ],
    });

    expect(features, hasLength(1));
    expect(features.first.osmId, 10);
    expect(features.first.name, 'Sé');
    final outer = features.first.polygons.single.outer;
    expect(outer.first.latitude, -23.55);
    expect(outer.first.longitude, -46.64);
  });

  test('lê buracos de um Polygon', () {
    final polygon = GeoJsonParser.parseGeometry({
      'type': 'Polygon',
      'coordinates': [
        [
          [0, 0],
          [4, 0],
          [4, 4],
          [0, 0],
        ],
        [
          [1, 1],
          [2, 1],
          [2, 2],
          [1, 1],
        ],
      ],
    }).single;

    expect(polygon.outer, hasLength(4));
    expect(polygon.holes, hasLength(1));
  });

  test('lê um MultiPolygon com vários pedaços', () {
    final polygons = GeoJsonParser.parseGeometry({
      'type': 'MultiPolygon',
      'coordinates': [
        [
          [
            [0, 0],
            [1, 0],
            [1, 1],
            [0, 0],
          ],
        ],
        [
          [
            [5, 5],
            [6, 5],
            [6, 6],
            [5, 5],
          ],
        ],
      ],
    });

    expect(polygons, hasLength(2));
  });

  test('ignora itens sem id ou com geometria desconhecida', () {
    final features = GeoJsonParser.parseFeatures({
      'features': [
        {
          'properties': {'name': 'sem id'},
          'geometry': {'type': 'Polygon', 'coordinates': []},
        },
        feature(1, 'ponto', {
          'type': 'Point',
          'coordinates': [0, 0],
        }),
      ],
    });

    expect(features, isEmpty);
  });

  test('resposta que não é um GeoJSON vira lista vazia', () {
    expect(GeoJsonParser.parseFeatures('texto'), isEmpty);
    expect(GeoJsonParser.parseFeatures({'features': 'x'}), isEmpty);
  });
}
