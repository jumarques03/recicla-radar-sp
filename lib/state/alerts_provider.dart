import 'dart:async';

import 'package:recicla_radar_sp/data/local/alert_seen_store.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Alertas calculados a partir dos dados. Recalcula sozinho quando a pessoa
/// muda o limiar de enchimento nas Configurações.
///
/// Também controla quais alertas já foram vistos: o selo da aba Alertas conta
/// só os ativos que a pessoa ainda não abriu nem marcou como vistos.
class AlertsProvider extends LoadableNotifier<List<Alert>> {
  AlertsProvider(this._repository, this._seenStore, [this._fillThreshold = 80])
      : _seen = _seenStore.load();

  final AlertRepository _repository;
  final AlertSeenStore _seenStore;
  int _fillThreshold;
  Set<String> _seen;

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

  List<Alert> get _alerts => data ?? const <Alert>[];

  int get activeCount => _alerts.where((a) => a.status.isActive).length;

  /// Alertas críticos que ainda precisam de atenção.
  List<Alert> get critical =>
      _alerts.where((a) => a.status.isActive && a.severity == AlertSeverity.critical).toList();

  /// Alertas ativos de uma lixeira.
  List<Alert> activeForBin(String binId) =>
      _alerts.where((a) => a.binId == binId && a.status.isActive).toList();

  /// Alertas ativos de um distrito (das lixeiras dele e os do distrito todo).
  List<Alert> activeForDistrict(String districtId) =>
      _alerts.where((a) => a.districtId == districtId && a.status.isActive).toList();

  // ------------------------------------------------------------------- vistos

  bool isSeen(String alertId) => _seen.contains(alertId);

  /// Alertas ativos que a pessoa ainda não viu. É o número do selo da aba.
  int get unseenCount => _alerts.where((a) => a.status.isActive && !_seen.contains(a.id)).length;

  Future<void> markSeen(String alertId) async {
    if (_seen.contains(alertId)) return;
    await _saveSeen({..._seen, alertId});
  }

  /// Alterna entre lido e não lido (botão de cada alerta na lista).
  Future<void> toggleSeen(String alertId) =>
      _seen.contains(alertId) ? markUnseen({alertId}) : markSeen(alertId);

  /// Marca todos os alertas atuais como vistos. Devolve os que eram novos, para
  /// a tela poder oferecer "Desfazer".
  Future<Set<String>> markAllSeen() async {
    final previouslyUnseen = _alerts.map((a) => a.id).where((id) => !_seen.contains(id)).toSet();
    await _saveSeen({..._seen, ...previouslyUnseen});
    return previouslyUnseen;
  }

  Future<void> markUnseen(Set<String> alertIds) => _saveSeen(_seen.difference(alertIds));

  Future<void> _saveSeen(Set<String> seen) async {
    _seen = seen;
    notifyListeners();
    await _seenStore.save(seen);
  }

  // ---------------------------------------------------------------- decisão

  /// Ação humana: quem decide é a pessoa, não o sistema.
  Future<void> updateStatus(String alertId, AlertStatus status) async {
    final updated = await _repository.updateStatus(alertId, status);
    replaceData([
      for (final alert in _alerts)
        if (alert.id == alertId) updated else alert,
    ]);
  }
}
