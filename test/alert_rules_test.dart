import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/domain/collection_drop_rule.dart';
import 'package:recicla_radar_sp/domain/coverage_rule.dart';
import 'package:recicla_radar_sp/domain/fill_prediction_rule.dart';
import 'package:recicla_radar_sp/domain/fill_trend.dart';
import 'package:recicla_radar_sp/domain/material_anomaly_rule.dart';
import 'package:recicla_radar_sp/domain/signal_loss_rule.dart';

/// Leituras da mais recente para a mais antiga, só com o enchimento.
List<Reading> fills(List<int> newestFirst) => [
      for (var i = 0; i < newestFirst.length; i++)
        Reading(
          binId: 'b',
          date: DateTime(2026, 11, 10).subtract(Duration(days: i)),
          fillPercent: newestFirst[i],
          kgByMaterial: const {},
        ),
    ];

void main() {
  group('FillTrend', () {
    test('calcula o ritmo médio desde a última coleta', () {
      final trend = FillTrend.estimate(fills([80, 60, 40, 20]))!;
      expect(trend.readingCount, 4);
      expect(trend.perDay, 20);
      expect(trend.perHour, closeTo(20 / 24, 0.0001));
      expect(trend.variation, 0);
    });

    test('para na coleta (enchimento que cai) e ignora leituras mais antigas', () {
      // 85 → 65 → 45 → 25 → (coleta) → 90 → 70
      final trend = FillTrend.estimate(fills([85, 65, 45, 25, 90, 70]))!;
      expect(trend.readingCount, 4);
      expect(trend.perDay, 20);
    });

    test('com menos de 4 leituras desde a coleta, não prevê', () {
      expect(FillTrend.estimate(fills([60, 40, 20, 90])), isNull);
      expect(FillTrend.estimate(fills([60])), isNull);
      expect(FillTrend.estimate(const []), isNull);
    });

    test('mede o quanto o ritmo varia', () {
      final steady = FillTrend.estimate(fills([80, 60, 40, 20]))!;
      final uneven = FillTrend.estimate(fills([90, 75, 40, 30]))!;
      expect(uneven.variation, greaterThan(steady.variation));
    });
  });

  group('FillPredictionRule', () {
    const rule = FillPredictionRule();

    test('não sugere alerta quando há folga e enche devagar', () {
      expect(rule.evaluate(currentFill: 30, fillPerHour: 0.5), isNull);
    });

    test('crítica até 4 h, alta até 12 h, média até 24 h', () {
      expect(rule.evaluate(currentFill: 92, fillPerHour: 2)!.severity, AlertSeverity.critical);
      expect(rule.evaluate(currentFill: 70, fillPerHour: 3)!.severity, AlertSeverity.high);
      expect(rule.evaluate(currentFill: 50, fillPerHour: 2.5)!.severity, AlertSeverity.medium);
    });

    test('sem previsão, passou do limiar gera alerta médio e acima de 95% alto', () {
      expect(rule.evaluate(currentFill: 85)!.severity, AlertSeverity.medium);
      expect(rule.evaluate(currentFill: 96)!.severity, AlertSeverity.high);
      expect(rule.evaluate(currentFill: 85)!.hasForecast, isFalse);
    });

    test('sem previsão e abaixo do limiar, não gera alerta', () {
      expect(rule.evaluate(currentFill: 60), isNull);
    });

    test('usa o limiar configurado pela pessoa', () {
      const strict = FillPredictionRule(thresholdPercent: 60);
      expect(strict.evaluate(currentFill: 65), isNotNull);
      expect(rule.evaluate(currentFill: 65), isNull);
    });

    test('lixeira cheia gera alerta crítico', () {
      expect(rule.evaluate(currentFill: 100, fillPerHour: 1)!.severity, AlertSeverity.critical);
    });
  });

  group('SignalLossRule', () {
    const rule = SignalLossRule();

    test('até 12 h sem sinal não gera alerta', () {
      expect(rule.evaluate(const Duration(hours: 12)), isNull);
    });

    test('mais de 12 h é alto e mais de 48 h é crítico', () {
      expect(rule.evaluate(const Duration(hours: 13))!.severity, AlertSeverity.high);
      expect(rule.evaluate(const Duration(hours: 48))!.severity, AlertSeverity.high);
      expect(rule.evaluate(const Duration(hours: 49))!.severity, AlertSeverity.critical);
      expect(rule.evaluate(const Duration(hours: 20))!.hours, 20);
    });
  });

  group('MaterialAnomalyRule', () {
    const rule = MaterialAnomalyRule();

    /// [recent] são os dias mais recentes; depois vêm 7 dias normais e 30 de base.
    List<double> series(List<double> recent) => [
          ...recent,
          ...List.filled(7 - recent.length, 5.0),
          ...List.filled(30, 5.0),
        ];

    test('2 dias seguidos acima de 2 vezes a média geram alerta de confiança baixa', () {
      final hit = rule.evaluate(series([12, 11]))!;
      expect(hit.runDays, 2);
      expect(hit.confidence, Confidence.low);
      expect(hit.severity, AlertSeverity.medium);
      expect(hit.baselineKg, 5);
    });

    test('um dia isolado não gera alerta', () {
      expect(rule.evaluate(series([12])), isNull);
      expect(rule.evaluate(series([12, 6])), isNull);
    });

    test('a confiança sobe com os dias seguidos', () {
      expect(rule.evaluate(series([12, 12, 12, 12]))!.confidence, Confidence.medium);
      expect(rule.evaluate(series([12, 12, 12, 12, 12]))!.confidence, Confidence.high);
    });

    test('a partir de 3 vezes a média a gravidade é alta', () {
      expect(rule.evaluate(series([16, 17]))!.severity, AlertSeverity.high);
    });

    test('sem dias suficientes de histórico, não avalia', () {
      expect(rule.evaluate(List.filled(20, 5)), isNull);
    });
  });

  group('CollectionDropRule', () {
    const rule = CollectionDropRule();
    const baseline = [100.0, 100.0, 100.0, 100.0];

    test('queda de até 15% não gera alerta', () {
      expect(
        rule.evaluate(lastWeekKg: 86, previousWeeksKg: baseline, binCount: 4, binsThatDropped: 4),
        isNull,
      );
    });

    test('queda entre 15% e 30% é média e acima de 30% é alta', () {
      final medium =
          rule.evaluate(lastWeekKg: 80, previousWeeksKg: baseline, binCount: 4, binsThatDropped: 4)!;
      final high =
          rule.evaluate(lastWeekKg: 60, previousWeeksKg: baseline, binCount: 4, binsThatDropped: 4)!;
      expect(medium.severity, AlertSeverity.medium);
      expect(medium.dropPercent, closeTo(20, 0.0001));
      expect(high.severity, AlertSeverity.high);
    });

    test('a confiança depende de quantas lixeiras caíram', () {
      Confidence confidence(int dropped) => rule
          .evaluate(lastWeekKg: 60, previousWeeksKg: baseline, binCount: 4, binsThatDropped: dropped)!
          .confidence;
      expect(confidence(4), Confidence.high);
      expect(confidence(2), Confidence.medium);
      expect(confidence(1), Confidence.low);
    });

    test('sem as 4 semanas anteriores, não avalia', () {
      expect(
        rule.evaluate(
          lastWeekKg: 10,
          previousWeeksKg: const [100, 100],
          binCount: 2,
          binsThatDropped: 2,
        ),
        isNull,
      );
    });
  });

  group('CoverageRule', () {
    const rule = CoverageRule();

    test('demanda alta com no máximo 2 lixeiras gera alerta', () {
      expect(rule.evaluate(demandIndex: 90, workingBins: 2)!.severity, AlertSeverity.medium);
      expect(rule.evaluate(demandIndex: 90, workingBins: 0)!.severity, AlertSeverity.high);
    });

    test('com demanda menor ou mais lixeiras, não gera alerta', () {
      expect(rule.evaluate(demandIndex: 84, workingBins: 1), isNull);
      expect(rule.evaluate(demandIndex: 95, workingBins: 3), isNull);
    });
  });
}
