import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Vistorias registradas neste aparelho.
class InspectionsProvider extends LoadableNotifier<List<Inspection>> {
  InspectionsProvider(this._repository);

  final InspectionRepository _repository;

  @override
  Future<List<Inspection>> fetch() => _repository.fetchAll();

  /// Vistorias de uma lixeira, da mais recente para a mais antiga.
  List<Inspection> forBin(String binId) =>
      (data ?? const <Inspection>[]).where((item) => item.binId == binId).toList();

  /// Vistorias que responderam se confirmam um alerta, da mais recente para a mais antiga.
  List<Inspection> checksFor(String alertId) => (data ?? const <Inspection>[])
      .where((item) => item.alertId == alertId && item.check != null)
      .toList();

  /// Última resposta de campo sobre o alerta, ou `null` se nenhuma vistoria o conferiu.
  Inspection? latestCheck(String alertId) {
    final checks = checksFor(alertId);
    return checks.isEmpty ? null : checks.first;
  }

  /// Quantos alertas já foram conferidos em campo e quantos deles foram confirmados.
  /// Vale a resposta mais recente de cada alerta.
  ({int checked, int confirmed}) get checkStats {
    final latest = <String, AlertCheck>{};
    for (final item in data ?? const <Inspection>[]) {
      final alertId = item.alertId;
      final check = item.check;
      if (alertId != null && check != null) latest.putIfAbsent(alertId, () => check);
    }
    final confirmed = latest.values.where((check) => check == AlertCheck.confirms).length;
    return (checked: latest.length, confirmed: confirmed);
  }

  Future<void> submit(Inspection inspection) async {
    await _repository.submit(inspection);
    replaceData([inspection, ...data ?? const <Inspection>[]]);
  }
}
