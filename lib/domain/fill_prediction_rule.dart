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

  /// Horas até a lixeira encher. Infinito quando não dá para prever.
  final double hoursToFull;
  final String rule;

  bool get hasForecast => hoursToFull.isFinite;
}

/// Regra de previsão de enchimento.
///
/// Sugere um alerta quando a lixeira passou do limiar de enchimento ou
/// quando deve ficar cheia em menos de [horizonHours] horas.
///
/// Gravidade pelo tempo até encher: crítica até 4 h, alta até 12 h, média até
/// 24 h e baixa acima disso. Sem previsão (poucas leituras), a gravidade vem só
/// do enchimento: alta a partir de 95% e média abaixo disso.
class FillPredictionRule {
  const FillPredictionRule({this.thresholdPercent = 80, this.horizonHours = 24});

  final int thresholdPercent;
  final double horizonHours;

  /// [fillPerHour] é quanto a lixeira enche, em pontos percentuais por hora.
  /// Passe `null` quando não for possível estimar o ritmo.
  AlertSuggestion? evaluate({required int currentFill, double? fillPerHour}) {
    final hasForecast = fillPerHour != null && fillPerHour > 0;
    if (currentFill >= 100) return _byHours(0);

    final hoursToFull = hasForecast ? (100 - currentFill) / fillPerHour : double.infinity;
    final overThreshold = currentFill >= thresholdPercent;
    if (!overThreshold && hoursToFull > horizonHours) return null;
    return hasForecast ? _byHours(hoursToFull) : _withoutForecast(currentFill);
  }

  AlertSuggestion _byHours(double hoursToFull) {
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
      rule: _ruleText,
    );
  }

  AlertSuggestion _withoutForecast(int currentFill) {
    return AlertSuggestion(
      type: AlertType.fillPrediction,
      severity: currentFill >= 95 ? AlertSeverity.high : AlertSeverity.medium,
      hoursToFull: double.infinity,
      rule: _ruleText,
    );
  }

  String get _ruleText =>
      'Alerta quando o enchimento passa de $thresholdPercent% ou quando a previsão de '
      'lotação é menor que ${horizonHours.round()} horas.';
}
