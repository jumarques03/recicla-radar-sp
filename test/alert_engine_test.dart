import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/domain/alert_engine.dart';

List<Alert> runEngine({int threshold = 80}) => const AlertEngine().run(AlertEngineInput(
      now: MockData.now,
      bins: MockData.bins,
      readingsByBin: MockData.readingsByBin,
      districts: MockData.districts,
      fillThreshold: threshold,
    ));

void main() {
  final alerts = runEngine();

  test('os dados geram alertas dos cinco tipos calculados a partir das leituras', () {
    // O tipo "vistoria" só aparece quando há vistorias registradas (veja inspection_flow_test).
    expect(
      alerts.map((a) => a.type).toSet(),
      AlertType.values.where((type) => type != AlertType.inspection).toSet(),
    );
  });

  test('há alertas de gravidades e confianças diferentes', () {
    expect(alerts.map((a) => a.severity).toSet().length, greaterThanOrEqualTo(3));
    expect(alerts.map((a) => a.confidence).toSet().length, 3);
  });

  test('cada alerta tem id único e o mesmo cálculo dá os mesmos ids', () {
    final ids = alerts.map((a) => a.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(runEngine().map((a) => a.id).toList(), ids);
  });

  test('todo alerta explica o que foi detectado, a regra, a confiança e as limitações', () {
    for (final alert in alerts) {
      expect(alert.detected, isNotEmpty, reason: alert.id);
      expect(alert.rule, isNotEmpty, reason: alert.id);
      expect(alert.confidenceReason, isNotEmpty, reason: alert.id);
      expect(alert.limitations, isNotEmpty, reason: alert.id);
      expect(alert.suggestedAction, isNotEmpty, reason: alert.id);
      expect(alert.evidence, isNotEmpty, reason: alert.id);
      expect(alert.status, AlertStatus.open, reason: alert.id);
    }
  });

  test('os alertas vêm dos mais graves para os menos graves', () {
    for (var i = 1; i < alerts.length; i++) {
      expect(alerts[i].severity.index, lessThanOrEqualTo(alerts[i - 1].severity.index));
    }
  });

  group('enchimento', () {
    final fillAlerts = alerts.where((a) => a.type == AlertType.fillPrediction).toList();
    Bin binOf(Alert alert) => MockData.bins.firstWhere((bin) => bin.id == alert.binId);

    test('só lixeiras funcionando geram alerta, e todas estão acima do limiar ou perto de encher', () {
      expect(fillAlerts, isNotEmpty);
      for (final alert in fillAlerts) {
        final bin = binOf(alert);
        expect(bin.status.isWorking, isTrue, reason: bin.name);
        expect(bin.fillPercent, greaterThanOrEqualTo(60), reason: bin.name);
      }
    });

    test('a lixeira mais cheia gera o alerta mais grave, e o texto cita o enchimento real', () {
      final fullest = [...MockData.bins]..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
      final alert = fillAlerts.firstWhere((a) => a.binId == fullest.first.id);
      expect(alert.severity, AlertSeverity.critical);
      expect(alert.detected, contains('${fullest.first.fillPercent}%'));
    });

    test('lixeira abaixo do limiar e sem previsão curta não gera alerta', () {
      final emptyish = MockData.bins.where((b) => b.fillPercent < 30).take(20);
      for (final bin in emptyish) {
        expect(fillAlerts.any((a) => a.binId == bin.id), isFalse, reason: bin.name);
      }
    });

    test('baixar o limiar nas Configurações só acrescenta alertas de enchimento', () {
      Set<String> fillIds(int threshold) => runEngine(threshold: threshold)
          .where((a) => a.type == AlertType.fillPrediction)
          .map((a) => a.id)
          .toSet();

      final strict = fillIds(95);
      final normal = fillIds(80);
      final loose = fillIds(60);
      expect(normal.containsAll(strict), isTrue);
      expect(loose.containsAll(normal), isTrue);
      expect(loose.length, greaterThan(normal.length));
    });

    test('o id muda depois de uma coleta, para o status antigo não valer para o problema novo', () {
      final bin = MockData.bins.firstWhere((b) => b.status.isWorking && b.fillPercent >= 88);
      final id = fillAlerts.firstWhere((a) => a.binId == bin.id).id;
      expect(id, startsWith('fill:${bin.id}:'));
      expect(id, endsWith('${bin.lastCollection.year}'
          '${bin.lastCollection.month.toString().padLeft(2, '0')}'
          '${bin.lastCollection.day.toString().padLeft(2, '0')}'));
    });
  });

  group('sem sinal', () {
    final offlineAlerts = alerts.where((a) => a.type == AlertType.offline).toList();

    test('só lixeiras com mais de 12 h de silêncio geram alerta', () {
      expect(offlineAlerts, isNotEmpty);
      for (final alert in offlineAlerts) {
        final bin = MockData.bins.firstWhere((b) => b.id == alert.binId);
        expect(MockData.now.difference(bin.lastSignalAt).inHours, greaterThan(12));
      }
    });

    test('lixeira em manutenção ou com sinal recente não gera alerta', () {
      final ids = offlineAlerts.map((a) => a.binId).toSet();
      for (final bin in MockData.bins) {
        final silent = MockData.now.difference(bin.lastSignalAt).inHours > 12;
        if (bin.status == BinStatus.maintenance || !silent) {
          expect(ids.contains(bin.id), isFalse, reason: bin.name);
        }
      }
    });

    test('a evidência mostra os dias sem leitura', () {
      for (final alert in offlineAlerts) {
        expect(alert.evidence.last, 0, reason: alert.title);
        expect(alert.evidence, contains(1));
      }
    });
  });

  group('volume', () {
    test('os aumentos de material e as quedas de coleta plantados nos dados são encontrados', () {
      final anomalyMaterials = alerts
          .where((a) => a.type == AlertType.anomaly)
          .map((a) => a.id.split(':')[2])
          .toSet();
      expect(anomalyMaterials, {'glass', 'plastic', 'metal'});

      final drops = alerts.where((a) => a.type == AlertType.lowCollection).map((a) => a.location);
      expect(drops, containsAll(['Itaquera', 'Penha', 'Santana']));
    });

    test('a queda maior que 30% é grave e a de 20% é média', () {
      Alert drop(String district) => alerts.firstWhere(
            (a) => a.type == AlertType.lowCollection && a.location == district,
          );
      expect(drop('Santana').severity, AlertSeverity.high);
      expect(drop('Penha').severity, AlertSeverity.medium);
    });

    test('aumento por mais dias seguidos tem mais confiança', () {
      Confidence confidenceOf(String material) => alerts
          .firstWhere((a) => a.type == AlertType.anomaly && a.id.contains(':$material:'))
          .confidence;
      expect(confidenceOf('glass'), Confidence.low); // 2 dias
      expect(confidenceOf('plastic'), Confidence.medium); // 4 dias
      expect(confidenceOf('metal'), Confidence.high); // 6 dias
    });
  });

  test('alerta de cobertura só aparece em distrito com demanda alta e poucas lixeiras', () {
    final coverage = alerts.where((a) => a.type == AlertType.lowCoverage);
    for (final alert in coverage) {
      final district = MockData.districts.firstWhere((d) => d.id == alert.id.split(':')[1]);
      final working = MockData.bins
          .where((b) => b.districtId == district.id && b.status.isWorking)
          .length;
      expect(district.demandIndex, greaterThanOrEqualTo(85));
      expect(working, lessThanOrEqualTo(2));
    }
  });
}
