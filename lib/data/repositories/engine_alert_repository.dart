import 'package:recicla_radar_sp/data/local/alert_history_store.dart';
import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/domain/alert_engine.dart';

/// Alertas calculados pelo motor a partir dos dados das lixeiras. O status e o
/// histórico de cada alerta vêm do aparelho: o motor sugere, a pessoa decide.
class EngineAlertRepository implements AlertRepository {
  EngineAlertRepository(
    this._store,
    this._inspections, {
    AlertHistoryStore? history,
    this._engine = const AlertEngine(),
  }) : _history = history ?? MemoryAlertHistoryStore();

  final AlertStatusStore _store;
  final InspectionRepository _inspections;
  final AlertHistoryStore _history;
  final AlertEngine _engine;
  List<Alert> _current = const [];

  @override
  Future<List<Alert>> fetchAlerts({required int fillThreshold}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final calculated = _engine.run(
      AlertEngineInput(
        now: MockData.now,
        bins: MockData.bins,
        readingsByBin: MockData.readingsByBin,
        districts: MockData.districts,
        fillThreshold: fillThreshold,
        inspections: await _inspections.fetchAll(),
      ),
    );
    final saved = _store.load();
    final history = _history.load();
    _current = [
      for (final alert in calculated)
        alert.copyWith(status: saved[alert.id] ?? alert.status, history: history[alert.id] ?? const []),
    ];
    return _current;
  }

  @override
  Future<Alert> updateStatus(String alertId, AlertStatus status) {
    return decide(
      alertId,
      AlertEvent(status: status, action: 'Mudou a situação para ${status.label}', at: DateTime.now()),
    );
  }

  @override
  Future<Alert> decide(String alertId, AlertEvent event) async {
    await _store.save(alertId, event.status);
    await _history.add(alertId, event);
    final index = _current.indexWhere((alert) => alert.id == alertId);
    final current = _current[index];
    final updated = current.copyWith(status: event.status, history: [...current.history, event]);
    _current = [..._current]..[index] = updated;
    return updated;
  }
}
