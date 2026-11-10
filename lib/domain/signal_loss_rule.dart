import 'package:recicla_radar_sp/data/models/alert.dart';

class SignalLossHit {
  const SignalLossHit({required this.severity, required this.hours});

  final AlertSeverity severity;
  final int hours;
}

/// Alerta quando o sensor fica muito tempo sem enviar leituras.
///
/// Mais de 12 horas sem sinal: gravidade alta. Mais de 48 horas: crítica.
class SignalLossRule {
  const SignalLossRule({this.alertAfterHours = 12, this.criticalAfterHours = 48});

  final int alertAfterHours;
  final int criticalAfterHours;

  SignalLossHit? evaluate(Duration silence) {
    if (silence.inHours <= alertAfterHours) return null;
    return SignalLossHit(
      severity: silence.inHours > criticalAfterHours
          ? AlertSeverity.critical
          : AlertSeverity.high,
      hours: silence.inHours,
    );
  }

  String get ruleText =>
      'Alerta quando não chega nenhuma leitura por mais de $alertAfterHours horas '
      '(crítico acima de $criticalAfterHours horas).';
}
