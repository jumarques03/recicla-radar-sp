import 'dart:math';

import 'package:recicla_radar_sp/data/models/reading.dart';

/// Ritmo de enchimento de uma lixeira desde a última coleta, calculado a
/// partir das leituras diárias.
class FillTrend {
  const FillTrend({required this.readingCount, required this.perDay, required this.variation});

  /// Leituras usadas, desde a última coleta.
  final int readingCount;

  /// Quantos pontos percentuais a lixeira enche por dia, em média.
  final double perDay;

  /// Quanto o ritmo variou de um dia para o outro (desvio padrão ÷ média).
  final double variation;

  double get perHour => perDay / 24;

  /// Menos leituras que isso não bastam para prever.
  static const int minReadings = 4;

  /// [readings] vem da mais recente para a mais antiga. A conta para na
  /// primeira queda do enchimento, que indica uma coleta. Devolve `null` quando
  /// há poucas leituras desde a última coleta.
  static FillTrend? estimate(List<Reading> readings) {
    final increases = <double>[];
    for (var i = 0; i + 1 < readings.length; i++) {
      final delta = readings[i].fillPercent - readings[i + 1].fillPercent;
      if (delta <= 0) break;
      increases.add(delta.toDouble());
    }
    if (increases.length + 1 < minReadings) return null;

    final mean = increases.reduce((a, b) => a + b) / increases.length;
    final variance =
        increases.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / increases.length;
    return FillTrend(
      readingCount: increases.length + 1,
      perDay: mean,
      variation: sqrt(variance) / mean,
    );
  }
}
