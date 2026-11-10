import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/domain/alert_engine.dart';

/// Alertas calculados pelo motor a partir dos dados das lixeiras. O status de
/// cada alerta vem do aparelho: o motor sugere, a pessoa decide.
class EngineAlertRepository implements AlertRepository {
  EngineAlertRepository(this._store, {this._engine = const AlertEngine()});

  final AlertStatusStore _store;
  final AlertEngine _engine;
  List<Alert> _current = const [];

  @override
  Future<List<Alert>> fetchAlerts({required int fillThreshold}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    final calculated = _engine.run(AlertEngineInput(
      now: MockData.now,
      bins: MockData.bins,
      readingsByBin: MockData.readingsByBin,
      districts: MockData.districts,
      fillThreshold: fillThreshold,
    ));
    final saved = _store.load();
    _current = [
      for (final alert in calculated) alert.copyWith(status: saved[alert.id] ?? alert.status),
    ];
    return _current;
  }

  @override
  Future<Alert> updateStatus(String alertId, AlertStatus status) async {
    await _store.save(alertId, status);
    final index = _current.indexWhere((alert) => alert.id == alertId);
    final updated = _current[index].copyWith(status: status);
    _current = [..._current]..[index] = updated;
    return updated;
  }
}
