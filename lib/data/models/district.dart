import 'package:latlong2/latlong.dart';

enum DemandLevel {
  low('Baixa'),
  medium('Média'),
  high('Alta');

  const DemandLevel(this.label);
  final String label;
}

class District {
  const District({
    required this.id,
    required this.name,
    required this.position,
    required this.demandIndex,
    required this.binCount,
    required this.history,
  });

  final String id;
  final String name;

  /// Centroide (aproximado) do distrito.
  final LatLng position;

  /// Estimativa de 0 a 100 da demanda de descarte.
  final int demandIndex;
  final int binCount;

  /// Índice das últimas semanas, da mais antiga para a mais recente.
  final List<int> history;

  DemandLevel get level {
    if (demandIndex >= 70) return DemandLevel.high;
    if (demandIndex >= 40) return DemandLevel.medium;
    return DemandLevel.low;
  }
}
