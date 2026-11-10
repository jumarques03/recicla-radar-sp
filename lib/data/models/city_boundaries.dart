import 'package:latlong2/latlong.dart';

/// Polígono: um anel externo e, se houver, buracos dentro dele.
class GeoPolygon {
  const GeoPolygon(this.outer, [this.holes = const []]);

  final List<LatLng> outer;
  final List<List<LatLng>> holes;
}

/// Limite de um distrito (pode ter mais de um pedaço).
class DistrictShape {
  const DistrictShape({required this.id, required this.name, required this.polygons});

  /// Mesmo id do distrito em `District`.
  final String id;
  final String name;
  final List<GeoPolygon> polygons;
}

/// Contorno do município de São Paulo e limites dos distritos, vindos do OpenStreetMap.
class CityBoundaries {
  const CityBoundaries({required this.city, required this.districts});

  const CityBoundaries.empty()
      : city = const [],
        districts = const {};

  final List<GeoPolygon> city;

  /// Distritos por id.
  final Map<String, DistrictShape> districts;

  bool get isEmpty => city.isEmpty && districts.isEmpty;
}
