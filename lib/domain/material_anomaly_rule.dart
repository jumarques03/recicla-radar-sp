import 'package:recicla_radar_sp/data/models/alert.dart';

class MaterialAnomalyHit {
  const MaterialAnomalyHit({
    required this.severity,
    required this.confidence,
    required this.runDays,
    required this.ratio,
    required this.baselineKg,
  });

  final AlertSeverity severity;
  final Confidence confidence;

  /// Dias seguidos acima do normal, até hoje.
  final int runDays;

  /// Quantas vezes o volume ficou acima da média.
  final double ratio;
  final double baselineKg;
}

/// Alerta quando um material passa de 2 vezes a média por pelo menos 2 dias
/// seguidos.
///
/// A média é a dos 30 dias anteriores à última semana (para o próprio aumento
/// não puxar a média para cima). Gravidade média; alta a partir de 3 vezes a
/// média. Confiança baixa com 2 dias seguidos, média com 3 ou 4 e alta com 5 ou mais.
class MaterialAnomalyRule {
  const MaterialAnomalyRule({
    this.factor = 2,
    this.minRunDays = 2,
    this.maxRunDays = 7,
    this.baselineDays = 30,
  });

  final double factor;
  final int minRunDays;
  final int maxRunDays;
  final int baselineDays;

  /// [dailyKg] vem do dia mais recente para o mais antigo. Precisa de pelo
  /// menos [maxRunDays] + [baselineDays] dias; com menos, não avalia.
  MaterialAnomalyHit? evaluate(List<double> dailyKg) {
    if (dailyKg.length < maxRunDays + baselineDays) return null;

    final baseline = dailyKg
            .skip(maxRunDays)
            .take(baselineDays)
            .reduce((a, b) => a + b) /
        baselineDays;
    if (baseline <= 0) return null;

    var run = 0;
    while (run < maxRunDays && dailyKg[run] > factor * baseline) {
      run++;
    }
    if (run < minRunDays) return null;

    final ratio = dailyKg.take(run).reduce((a, b) => a + b) / run / baseline;
    return MaterialAnomalyHit(
      severity: ratio >= 3 ? AlertSeverity.high : AlertSeverity.medium,
      confidence: run >= 5
          ? Confidence.high
          : run >= 3
              ? Confidence.medium
              : Confidence.low,
      runDays: run,
      ratio: ratio,
      baselineKg: baseline,
    );
  }

  String get ruleText =>
      'Alerta quando um material passa de ${factor.round()} vezes a média de $baselineDays dias '
      'por $minRunDays dias seguidos ou mais.';
}
