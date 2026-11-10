import 'package:recicla_radar_sp/data/models/alert.dart';

class CollectionDropHit {
  const CollectionDropHit({
    required this.severity,
    required this.confidence,
    required this.dropPercent,
  });

  final AlertSeverity severity;
  final Confidence confidence;

  /// Queda em relação à média das semanas anteriores, em %.
  final double dropPercent;
}

/// Alerta quando o volume coletado em um distrito nos últimos 7 dias cai mais
/// de 15% em relação à média das 4 semanas anteriores.
///
/// Gravidade média; alta quando a queda passa de 30%. Confiança pela parte das
/// lixeiras do distrito que também caíram: 75% ou mais é alta, 50% ou mais é
/// média e abaixo disso é baixa.
class CollectionDropRule {
  const CollectionDropRule({this.alertDrop = 0.15, this.highDrop = 0.30});

  final double alertDrop;
  final double highDrop;

  /// Queda entre 0 e 1 (0,2 = caiu 20%). Negativa quando subiu.
  double drop({required double lastWeekKg, required double baselineKg}) =>
      baselineKg <= 0 ? 0 : (baselineKg - lastWeekKg) / baselineKg;

  /// [previousWeeksKg] são as 4 semanas anteriores. Precisa de todas, com
  /// volume; com menos, não avalia.
  CollectionDropHit? evaluate({
    required double lastWeekKg,
    required List<double> previousWeeksKg,
    required int binCount,
    required int binsThatDropped,
  }) {
    if (previousWeeksKg.length < 4 || binCount == 0) return null;
    final baseline = previousWeeksKg.reduce((a, b) => a + b) / previousWeeksKg.length;
    if (baseline <= 0) return null;

    final dropped = drop(lastWeekKg: lastWeekKg, baselineKg: baseline);
    if (dropped <= alertDrop) return null;

    final share = binsThatDropped / binCount;
    return CollectionDropHit(
      severity: dropped > highDrop ? AlertSeverity.high : AlertSeverity.medium,
      confidence: share >= 0.75
          ? Confidence.high
          : share >= 0.5
              ? Confidence.medium
              : Confidence.low,
      dropPercent: dropped * 100,
    );
  }

  String get ruleText =>
      'Alerta quando o volume cai mais de ${(alertDrop * 100).round()}% contra a média de 4 '
      'semanas (alta acima de ${(highDrop * 100).round()}%).';
}
