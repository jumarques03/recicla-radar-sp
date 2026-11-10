import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:recicla_radar_sp/data/local/alert_status_store.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/data/repositories/engine_alert_repository.dart';
import 'package:recicla_radar_sp/state/alerts_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

Future<SharedPreferences> freshPrefs([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return SharedPreferences.getInstance();
}

void main() {
  group('AlertStatusStore', () {
    test('guarda o status e devolve depois de "fechar e abrir" o app', () async {
      final prefs = await freshPrefs();
      await SharedPrefsAlertStatusStore(prefs).save('a1', AlertStatus.resolved);
      await SharedPrefsAlertStatusStore(prefs).save('a2', AlertStatus.inAnalysis);

      // Um novo objeto sobre os mesmos dados do aparelho, como num app reaberto.
      final reopened = SharedPrefsAlertStatusStore(prefs).load();
      expect(reopened, {'a1': AlertStatus.resolved, 'a2': AlertStatus.inAnalysis});
    });

    test('voltar para "aberto" apaga o registro', () async {
      final prefs = await freshPrefs();
      final store = SharedPrefsAlertStatusStore(prefs);
      await store.save('a1', AlertStatus.discarded);
      await store.save('a1', AlertStatus.open);
      expect(store.load(), isEmpty);
    });

    test('dado corrompido ou desconhecido não derruba o app', () async {
      final broken = await freshPrefs({SharedPrefsAlertStatusStore.storageKey: '{não é json'});
      expect(SharedPrefsAlertStatusStore(broken).load(), isEmpty);

      final unknown = await freshPrefs({
        SharedPrefsAlertStatusStore.storageKey: '{"a1":"resolved","a2":"statusinexistente"}',
      });
      expect(SharedPrefsAlertStatusStore(unknown).load(), {'a1': AlertStatus.resolved});
    });
  });

  group('EngineAlertRepository', () {
    test('o status escolhido continua depois de recalcular os alertas', () async {
      final prefs = await freshPrefs();
      final first = EngineAlertRepository(SharedPrefsAlertStatusStore(prefs));
      final alerts = await first.fetchAlerts(fillThreshold: 80);
      final target = alerts.first;
      expect(target.status, AlertStatus.open);

      final updated = await first.updateStatus(target.id, AlertStatus.resolved);
      expect(updated.status, AlertStatus.resolved);

      final second = EngineAlertRepository(SharedPrefsAlertStatusStore(prefs));
      final reloaded = await second.fetchAlerts(fillThreshold: 80);
      expect(reloaded.firstWhere((a) => a.id == target.id).status, AlertStatus.resolved);
      expect(reloaded.where((a) => a.id != target.id).every((a) => a.status == AlertStatus.open), isTrue);
    });

    test('mudar o limiar recalcula os alertas sem perder o status', () async {
      final prefs = await freshPrefs();
      final repository = EngineAlertRepository(SharedPrefsAlertStatusStore(prefs));
      final normal = await repository.fetchAlerts(fillThreshold: 80);
      final target = normal.firstWhere((a) => a.type == AlertType.fillPrediction);
      await repository.updateStatus(target.id, AlertStatus.discarded);

      final loose = await repository.fetchAlerts(fillThreshold: 60);
      expect(loose.length, greaterThan(normal.length));
      expect(loose.firstWhere((a) => a.id == target.id).status, AlertStatus.discarded);
    });
  });

  group('AlertsProvider', () {
    test('recalcula quando o limiar muda e não recalcula se ficou igual', () async {
      final repository = _RecordingRepository();
      final provider = AlertsProvider(repository, 80);

      await provider.load();
      expect(repository.thresholds, [80]);

      provider.applyThreshold(80);
      await Future<void>.delayed(Duration.zero);
      expect(repository.thresholds, [80]);

      provider.applyThreshold(60);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(repository.thresholds, [80, 60]);
      expect(provider.status, LoadStatus.ready);
    });
  });
}

class _RecordingRepository implements AlertRepository {
  final List<int> thresholds = [];

  @override
  Future<List<Alert>> fetchAlerts({required int fillThreshold}) async {
    thresholds.add(fillThreshold);
    return const [];
  }

  @override
  Future<Alert> updateStatus(String alertId, AlertStatus status) =>
      throw UnimplementedError();
}
