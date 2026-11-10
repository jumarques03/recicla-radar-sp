import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/models/city_boundaries.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';

/// Limites de teste, sem internet: um quadrado para a cidade e um quadradinho
/// em volta de cada distrito.
class FakeBoundaryRepository implements BoundaryRepository {
  @override
  Future<CityBoundaries> fetchBoundaries() async {
    List<LatLng> square(LatLng center, double half) => [
          LatLng(center.latitude - half, center.longitude - half),
          LatLng(center.latitude - half, center.longitude + half),
          LatLng(center.latitude + half, center.longitude + half),
          LatLng(center.latitude + half, center.longitude - half),
        ];

    return CityBoundaries(
      city: [GeoPolygon(square(const LatLng(-23.68, -46.6), 0.35))],
      districts: {
        for (final district in MockData.districts)
          district.id: DistrictShape(
            id: district.id,
            name: district.name,
            polygons: [GeoPolygon(square(district.position, 0.01))],
          ),
      },
    );
  }
}
