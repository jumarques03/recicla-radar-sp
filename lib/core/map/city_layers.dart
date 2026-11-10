import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/models/city_boundaries.dart';

/// Camadas do contorno de São Paulo, para pôr dentro de um `FlutterMap`.
abstract final class CityLayers {
  /// Azul forte do contorno da cidade.
  static const Color outlineColor = Color(0xFF0D47A1);

  /// Cor fina da borda entre distritos.
  static const Color districtBorder = Color(0xFF37474F);

  // Retângulo grande, só para escurecer tudo que fica fora de São Paulo.
  static const List<LatLng> _surroundings = [
    LatLng(-26, -49),
    LatLng(-26, -44),
    LatLng(-21, -44),
    LatLng(-21, -49),
  ];

  /// Escurece a área de fora do município, destacando o foco do app.
  static Widget dimOutside(CityBoundaries boundaries) {
    return PolygonLayer(
      polygons: [
        Polygon(
          points: _surroundings,
          holePointsList: [for (final polygon in boundaries.city) polygon.outer],
          color: const Color(0xFF000000).withValues(alpha: 0.38),
        ),
      ],
    );
  }

  /// Borda fina de todos os distritos, sem preenchimento.
  static Widget districtBorders(CityBoundaries boundaries, {double width = 1.2}) {
    return PolygonLayer(
      polygons: [
        for (final district in boundaries.districts.values)
          for (final polygon in district.polygons)
            Polygon(
              points: polygon.outer,
              holePointsList: polygon.holes,
              borderStrokeWidth: width,
              borderColor: districtBorder.withValues(alpha: 0.8),
            ),
      ],
    );
  }

  /// Contorno forte do município: uma linha branca por baixo e outra azul por cima.
  static List<Widget> outline(CityBoundaries boundaries) {
    return [
      PolygonLayer(
        polygons: [
          for (final polygon in boundaries.city)
            Polygon(
              points: polygon.outer,
              borderStrokeWidth: 8,
              borderColor: Colors.white.withValues(alpha: 0.9),
            ),
        ],
      ),
      PolygonLayer(
        polygons: [
          for (final polygon in boundaries.city)
            Polygon(
              points: polygon.outer,
              borderStrokeWidth: 4,
              borderColor: outlineColor,
            ),
        ],
      ),
    ];
  }
}
