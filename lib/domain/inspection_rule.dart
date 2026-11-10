import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';

class InspectionHit {
  const InspectionHit({required this.severity});

  final AlertSeverity severity;
}

/// Alerta quando uma vistoria recente (até 7 dias) é grave ou aponta lixeira
/// danificada ou vandalizada, ou seja, a coleta pode estar comprometida.
///
/// Gravidade alta com pedido de coleta ou reparo é crítica; gravidade alta sem
/// pedido é alta; danificada ou vandalizada com gravidade menor é média.
class InspectionRule {
  const InspectionRule({this.recentDays = 7});

  final int recentDays;

  InspectionHit? evaluate(Inspection inspection, DateTime now) {
    if (now.difference(inspection.dateTime) > Duration(days: recentDays)) return null;

    final isSerious = inspection.severity == InspectionSeverity.high;
    final isDamaged = inspection.type == OccurrenceType.damaged ||
        inspection.type == OccurrenceType.vandalized;
    if (!isSerious && !isDamaged) return null;

    return InspectionHit(
      severity: isSerious
          ? (inspection.needsAction ? AlertSeverity.critical : AlertSeverity.high)
          : AlertSeverity.medium,
    );
  }

  String get ruleText =>
      'Alerta quando uma vistoria dos últimos $recentDays dias tem gravidade alta ou aponta '
      'lixeira danificada ou vandalizada.';
}
