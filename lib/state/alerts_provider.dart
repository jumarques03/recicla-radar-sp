import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

class AlertsProvider extends LoadableNotifier<List<Alert>> {
  AlertsProvider(this._repository);

  final AlertRepository _repository;

  @override
  Future<List<Alert>> fetch() async {
    final alerts = await _repository.fetchAlerts();
    return [...alerts]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Alert? byId(String id) {
    for (final alert in data ?? const <Alert>[]) {
      if (alert.id == id) return alert;
    }
    return null;
  }

  int get activeCount => (data ?? const <Alert>[]).where((a) => a.status.isActive).length;

  /// Alertas críticos que ainda precisam de atenção.
  List<Alert> get critical => (data ?? const <Alert>[])
      .where((a) => a.status.isActive && a.severity == AlertSeverity.critical)
      .toList();

  /// Ação humana: quem decide é a pessoa, não o sistema.
  Future<void> updateStatus(String alertId, AlertStatus status) async {
    final updated = await _repository.updateStatus(alertId, status);
    replaceData([
      for (final alert in data ?? const <Alert>[])
        if (alert.id == alertId) updated else alert,
    ]);
  }
}
