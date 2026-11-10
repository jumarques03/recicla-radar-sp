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
    required this.recoveryRate,
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

  /// Parte do coletado que é reaproveitada (suposição, de 0 a 1).
  final double recoveryRate;
  final List<SeriesPoint> series;

  /// "dia" ou "semana".
  final String seriesUnit;
  final Map<WasteMaterial, double> byMaterial;

  /// Variação em relação ao período anterior de mesmo tamanho.
  double get variationPercent =>
      previousKg == 0 ? 0 : (totalKg - previousKg) / previousKg * 100;
}
