import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/models/city_boundaries.dart';

/// Um item do GeoJSON devolvido pelo Nominatim.
class OsmFeature {
  const OsmFeature({required this.osmId, required this.name, required this.polygons});

  final int osmId;
  final String name;
  final List<GeoPolygon> polygons;
}

/// Lê o GeoJSON do Nominatim (`FeatureCollection` com `Polygon` e `MultiPolygon`).
abstract final class GeoJsonParser {
  static List<OsmFeature> parseFeatures(Object? json) {
    if (json is! Map<String, dynamic>) return const [];
    final features = json['features'];
    if (features is! List) return const [];

    final result = <OsmFeature>[];
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map<String, dynamic> || geometry is! Map<String, dynamic>) continue;
      final osmId = properties['osm_id'];
      if (osmId is! num) continue;

      final polygons = parseGeometry(geometry);
      if (polygons.isEmpty) continue;
      result.add(OsmFeature(
        osmId: osmId.toInt(),
        name: properties['name'] as String? ?? '',
        polygons: polygons,
      ));
    }
    return result;
  }

  static List<GeoPolygon> parseGeometry(Map<String, dynamic> geometry) {
    final coordinates = geometry['coordinates'];
    if (coordinates is! List) return const [];
    return switch (geometry['type']) {
      'Polygon' => [_parsePolygon(coordinates)],
      'MultiPolygon' => [
          for (final polygon in coordinates)
            if (polygon is List) _parsePolygon(polygon),
        ],
      _ => const [],
    };
  }

  static GeoPolygon _parsePolygon(List<dynamic> rings) {
    final parsed = [for (final ring in rings) if (ring is List) _parseRing(ring)];
    return GeoPolygon(parsed.first, parsed.skip(1).toList());
  }

  /// No GeoJSON cada ponto é `[longitude, latitude]`.
  static List<LatLng> _parseRing(List<dynamic> ring) {
    return [
      for (final point in ring)
        if (point is List && point.length >= 2)
          LatLng((point[1] as num).toDouble(), (point[0] as num).toDouble()),
    ];
  }
}
