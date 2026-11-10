import 'dart:async';

import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Alertas calculados a partir dos dados. Recalcula sozinho quando a pessoa
/// muda o limiar de enchimento nas Configurações.
class AlertsProvider extends LoadableNotifier<List<Alert>> {
  AlertsProvider(this._repository, [this._fillThreshold = 80]);

  final AlertRepository _repository;
  int _fillThreshold;

  void applyThreshold(int fillThreshold) {
    if (fillThreshold == _fillThreshold) return;
    _fillThreshold = fillThreshold;
    // Adiado para não notificar durante a construção da árvore de widgets.
    scheduleMicrotask(load);
  }

  @override
  Future<List<Alert>> fetch() => _repository.fetchAlerts(fillThreshold: _fillThreshold);

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
