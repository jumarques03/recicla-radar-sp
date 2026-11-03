import 'package:recicla_radar_sp/data/models/alert.dart';

/// Resultado de uma regra: o motor sugere, a pessoa decide.
class AlertSuggestion {
  const AlertSuggestion({
    required this.type,
    required this.severity,
    required this.hoursToFull,
    required this.rule,
  });

  final AlertType type;
  final AlertSeverity severity;
  final double hoursToFull;
  final String rule;
}

/// Regra de exemplo do futuro motor de alertas.
///
/// Sugere um alerta quando a lixeira passou do limiar de enchimento ou
/// quando deve ficar cheia em menos de [horizonHours] horas.
class FillPredictionRule {
  const FillPredictionRule({this.thresholdPercent = 80, this.horizonHours = 24});

  final int thresholdPercent;
  final double horizonHours;

  /// [fillPerHour] é quanto a lixeira enche, em pontos percentuais por hora.
  AlertSuggestion? evaluate({required int currentFill, required double fillPerHour}) {
    if (currentFill >= 100) return _suggest(0);
    final hoursToFull = fillPerHour > 0 ? (100 - currentFill) / fillPerHour : double.infinity;
    final overThreshold = currentFill >= thresholdPercent;
    if (!overThreshold && hoursToFull > horizonHours) return null;
    return _suggest(hoursToFull);
  }

  AlertSuggestion _suggest(double hoursToFull) {
    final severity = switch (hoursToFull) {
      <= 4 => AlertSeverity.critical,
      <= 12 => AlertSeverity.high,
      <= 24 => AlertSeverity.medium,
      _ => AlertSeverity.low,
    };
    return AlertSuggestion(
      type: AlertType.fillPrediction,
      severity: severity,
      hoursToFull: hoursToFull,
      rule: 'Enchimento acima de $thresholdPercent% ou lotação prevista em menos de '
          '${horizonHours.round()} horas.',
    );
  }
}
