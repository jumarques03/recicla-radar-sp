import 'package:flutter_test/flutter_test.dart';

import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/domain/fill_prediction_rule.dart';

void main() {
  const rule = FillPredictionRule();

  test('não sugere alerta quando há folga e enche devagar', () {
    expect(rule.evaluate(currentFill: 30, fillPerHour: 0.5), isNull);
  });

  test('sugere alerta crítico quando enche em até 4 horas', () {
    final suggestion = rule.evaluate(currentFill: 92, fillPerHour: 2);
    expect(suggestion, isNotNull);
    expect(suggestion!.hoursToFull, 4);
    expect(suggestion.severity, AlertSeverity.critical);
  });

  test('sugere alerta quando passa do limiar, mesmo sem previsão', () {
    final suggestion = rule.evaluate(currentFill: 85, fillPerHour: 0);
    expect(suggestion, isNotNull);
    expect(suggestion!.severity, AlertSeverity.low);
  });

  test('usa o limiar configurado pela pessoa', () {
    const strict = FillPredictionRule(thresholdPercent: 60);
    expect(strict.evaluate(currentFill: 65, fillPerHour: 0), isNotNull);
    expect(rule.evaluate(currentFill: 65, fillPerHour: 0), isNull);
  });

  test('lixeira cheia gera alerta crítico', () {
    final suggestion = rule.evaluate(currentFill: 100, fillPerHour: 1);
    expect(suggestion!.severity, AlertSeverity.critical);
  });
}
