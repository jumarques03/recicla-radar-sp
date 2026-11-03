import 'package:recicla_radar_sp/data/models/waste_material.dart';

class SeriesPoint {
  const SeriesPoint(this.label, this.value);

  final String label;
  final double value;
}

/// Números da tela de visão geral para um período.
class OverviewSummary {
  const OverviewSummary({
    required this.days,
    required this.totalKg,
    required this.previousKg,
    required this.operatingPercent,
    required this.divertedKg,
    required this.series,
    required this.seriesUnit,
    required this.byMaterial,
  });

  final int days;
  final double totalKg;
  final double previousKg;
  final int operatingPercent;

  /// Material que deixou de ir para o aterro e foi para cooperativas.
  final double divertedKg;
  final List<SeriesPoint> series;

  /// "dia" ou "semana".
  final String seriesUnit;
  final Map<WasteMaterial, double> byMaterial;

  /// Variação em relação ao período anterior de mesmo tamanho.
  double get variationPercent =>
      previousKg == 0 ? 0 : (totalKg - previousKg) / previousKg * 100;
}
