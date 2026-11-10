import 'package:recicla_radar_sp/data/models/alert.dart';

class CoverageHit {
  const CoverageHit({required this.severity});

  final AlertSeverity severity;
}

/// Alerta quando um distrito tem demanda muito alta e poucas lixeiras
/// funcionando: índice de 85 ou mais e no máximo 2 lixeiras. Gravidade média;
/// alta quando não há nenhuma lixeira funcionando.
class CoverageRule {
  const CoverageRule({this.minDemandIndex = 85, this.maxWorkingBins = 2});

  final int minDemandIndex;
  final int maxWorkingBins;

  CoverageHit? evaluate({required int demandIndex, required int workingBins}) {
    if (demandIndex < minDemandIndex || workingBins > maxWorkingBins) return null;
    return CoverageHit(
      severity: workingBins == 0 ? AlertSeverity.high : AlertSeverity.medium,
    );
  }

  String get ruleText =>
      'Alerta quando o índice de demanda é $minDemandIndex ou mais e há no máximo '
      '$maxWorkingBins lixeiras funcionando no distrito.';
}
