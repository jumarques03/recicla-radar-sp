import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';
import 'package:recicla_radar_sp/domain/collection_drop_rule.dart';
import 'package:recicla_radar_sp/domain/coverage_rule.dart';
import 'package:recicla_radar_sp/domain/fill_prediction_rule.dart';
import 'package:recicla_radar_sp/domain/fill_trend.dart';
import 'package:recicla_radar_sp/domain/material_anomaly_rule.dart';
import 'package:recicla_radar_sp/domain/signal_loss_rule.dart';

/// Tudo que o motor lê para calcular os alertas.
class AlertEngineInput {
  const AlertEngineInput({
    required this.now,
    required this.bins,
    required this.readingsByBin,
    required this.districts,
    required this.fillThreshold,
  });

  final DateTime now;
  final List<Bin> bins;

  /// Leituras diárias de cada lixeira, da mais recente para a mais antiga.
  final Map<String, List<Reading>> readingsByBin;
  final List<District> districts;

  /// Enchimento (%) a partir do qual uma lixeira gera alerta (Configurações).
  final int fillThreshold;
}

/// Calcula os alertas a partir dos dados. Ele só sugere: o status de cada
/// alerta (em análise, resolvido, descartado) é decisão de uma pessoa e é
/// aplicado depois, por cima do resultado.
///
/// O id de cada alerta é estável: o mesmo problema gera o mesmo id enquanto
/// durar, e um novo problema (por exemplo, depois de uma coleta) gera outro.
class AlertEngine {
  const AlertEngine({
    this.signalLoss = const SignalLossRule(),
    this.anomaly = const MaterialAnomalyRule(),
    this.collectionDrop = const CollectionDropRule(),
    this.coverage = const CoverageRule(),
  });

  final SignalLossRule signalLoss;
  final MaterialAnomalyRule anomaly;
  final CollectionDropRule collectionDrop;
  final CoverageRule coverage;

  List<Alert> run(AlertEngineInput input) {
    final alerts = <Alert>[
      ..._fillAlerts(input),
      ..._signalAlerts(input),
      ..._anomalyAlerts(input),
      ..._collectionAlerts(input),
      ..._coverageAlerts(input),
    ];
    // Mais graves primeiro; em empate, o mais recente.
    alerts.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0 ? bySeverity : b.createdAt.compareTo(a.createdAt);
    });
    return alerts;
  }

  // ---------------------------------------------------------------- enchimento

  List<Alert> _fillAlerts(AlertEngineInput input) {
    final rule = FillPredictionRule(thresholdPercent: input.fillThreshold);
    final alerts = <Alert>[];

    for (final bin in input.bins.where((bin) => bin.status.isWorking)) {
      final readings = input.readingsByBin[bin.id] ?? const <Reading>[];
      final trend = FillTrend.estimate(readings);
      final suggestion = rule.evaluate(currentFill: bin.fillPercent, fillPerHour: trend?.perHour);
      if (suggestion == null) continue;

      final confidence = _fillConfidence(trend);
      final hours = suggestion.hasForecast ? suggestion.hoursToFull.ceil() : null;

      alerts.add(Alert(
        id: 'fill:${bin.id}:${_ymd(bin.lastCollection)}',
        title: hours == null
            ? '${bin.name} passou de ${input.fillThreshold}% de enchimento'
            : '${bin.name} deve encher em ${hours < 1 ? 'menos de 1' : '$hours'} h',
        type: AlertType.fillPrediction,
        severity: suggestion.severity,
        status: AlertStatus.open,
        confidence: confidence,
        createdAt: _fillCreatedAt(input.now, bin, trend, input.fillThreshold),
        location: bin.address,
        binId: bin.id,
        detected: trend == null
            ? 'A lixeira está com ${bin.fillPercent}% de enchimento, acima do limite de '
                '${input.fillThreshold}%. Ainda não há leituras suficientes desde a última coleta '
                'para prever quando ela enche.'
            : 'A lixeira está com ${bin.fillPercent}% de enchimento e enche cerca de '
                '${Formatters.decimal(trend.perHour)}% por hora (média dos últimos '
                '${trend.readingCount - 1} dias desde a última coleta). No ritmo atual, ela fica '
                'cheia em aproximadamente $hours horas.',
        evidence: _lastSevenDays(readings, (r) => r.fillPercent.toDouble()),
        evidenceLabel: 'Enchimento (%) nos últimos 7 dias',
        rule: suggestion.rule,
        confidenceReason: trend == null
            ? 'Há menos de ${FillTrend.minReadings} leituras desde a última coleta, então o '
                'tempo até encher não pôde ser calculado.'
            : 'Foram ${trend.readingCount} leituras desde a última coleta e o ritmo de '
                '${trend.variation <= 0.25 ? 'enchimento variou pouco' : 'enchimento variou bastante'} '
                'de um dia para o outro.',
        limitations:
            'A previsão não considera feriados, eventos na região nem coletas extras já programadas.',
        suggestedAction: suggestion.severity.index >= AlertSeverity.high.index
            ? 'Priorize a coleta desta lixeira ainda hoje. Se já foi coletada, marque como resolvido.'
            : 'Inclua esta lixeira na próxima rota de coleta.',
      ));
    }
    return alerts;
  }

  Confidence _fillConfidence(FillTrend? trend) {
    if (trend == null) return Confidence.low;
    if (trend.readingCount >= 5 && trend.variation <= 0.25) return Confidence.high;
    if (trend.variation <= 0.5) return Confidence.medium;
    return Confidence.low;
  }

  /// Quando a lixeira passou do ponto que gerou o alerta (o limiar ou a
  /// previsão de 24 h, o que veio primeiro).
  DateTime _fillCreatedAt(DateTime now, Bin bin, FillTrend? trend, int threshold) {
    final latest = now.subtract(const Duration(minutes: 5));
    if (trend == null) return latest;
    final triggerFill = [threshold.toDouble(), 100 - 24 * trend.perHour].reduce((a, b) => a < b ? a : b);
    final crossed = bin.lastCollection.add(Duration(minutes: (triggerFill / trend.perHour * 60).round()));
    if (crossed.isAfter(latest)) return latest;
    return crossed.isBefore(bin.lastCollection) ? bin.lastCollection : crossed;
  }

  // ---------------------------------------------------------------- sem sinal

  List<Alert> _signalAlerts(AlertEngineInput input) {
    final alerts = <Alert>[];
    final today = _day(input.now);

    // Lixeira em manutenção já está sendo tratada, então não gera alerta.
    for (final bin in input.bins.where((bin) => bin.status != BinStatus.maintenance)) {
      final hit = signalLoss.evaluate(input.now.difference(bin.lastSignalAt));
      if (hit == null) continue;

      final readings = input.readingsByBin[bin.id] ?? const <Reading>[];
      final datesWithReadings = {for (final reading in readings) reading.date};

      alerts.add(Alert(
        id: 'offline:${bin.id}:${_ymd(bin.lastSignalAt)}',
        title: '${bin.name} está sem sinal',
        type: AlertType.offline,
        severity: hit.severity,
        status: AlertStatus.open,
        confidence: Confidence.high,
        createdAt: bin.lastSignalAt,
        location: bin.address,
        binId: bin.id,
        detected: 'O sensor não envia leituras há ${hit.hours} horas.',
        evidence: [
          for (var back = 6; back >= 0; back--)
            datesWithReadings.contains(today.subtract(Duration(days: back))) ? 1.0 : 0.0,
        ],
        evidenceLabel: 'Leituras recebidas por dia (1 = recebeu)',
        rule: signalLoss.ruleText,
        confidenceReason: 'A falha de comunicação é confirmada pela ausência total de leituras.',
        limitations: 'Não sabemos se o problema é a bateria, o chip ou a lixeira.',
        suggestedAction: 'Envie um fiscal para conferir o equipamento e registre uma vistoria.',
      ));
    }
    return alerts;
  }

  // ------------------------------------------------------------ fora do padrão

  List<Alert> _anomalyAlerts(AlertEngineInput input) {
    final alerts = <Alert>[];

    for (final bin in input.bins.where((bin) => bin.status.isWorking)) {
      final readings = input.readingsByBin[bin.id] ?? const <Reading>[];
      for (final material in WasteMaterial.values) {
        final dailyKg = [for (final reading in readings) reading.kgByMaterial[material] ?? 0.0];
        final hit = anomaly.evaluate(dailyKg);
        if (hit == null) continue;

        final material0 = material.label.toLowerCase();
        alerts.add(Alert(
          id: 'anomaly:${bin.id}:${material.name}:${_ymd(readings[hit.runDays - 1].date)}',
          title: 'Aumento incomum de $material0 em ${bin.name}',
          type: AlertType.anomaly,
          severity: hit.severity,
          status: AlertStatus.open,
          confidence: hit.confidence,
          createdAt: readings[hit.runDays - 1].date,
          location: bin.address,
          binId: bin.id,
          detected: 'A quantidade de $material0 foi ${Formatters.decimal(hit.ratio)} vezes maior '
              'que a média de ${Formatters.kg(hit.baselineKg)} por dia, por ${hit.runDays} dias seguidos.',
          evidence: _lastSevenDays(readings, (r) => r.kgByMaterial[material] ?? 0),
          evidenceLabel: '${material.label} coletado (kg) nos últimos 7 dias',
          rule: anomaly.ruleText,
          confidenceReason: switch (hit.confidence) {
            Confidence.low => 'Foram só ${hit.runDays} dias fora do padrão. Pode ser um evento pontual.',
            Confidence.medium => 'O aumento já dura ${hit.runDays} dias, o que reduz a chance de ser pontual.',
            Confidence.high => 'O aumento já dura ${hit.runDays} dias seguidos, então não parece pontual.',
          },
          limitations: 'Não sabemos se houve festa, obra ou erro de leitura na região.',
          suggestedAction: hit.confidence == Confidence.low
              ? 'Acompanhe por mais alguns dias antes de tomar qualquer providência.'
              : 'Verifique o que mudou perto desta lixeira e se ela precisa de coletas mais frequentes.',
        ));
      }
    }
    return alerts;
  }

  // --------------------------------------------------------- coleta abaixo

  List<Alert> _collectionAlerts(AlertEngineInput input) {
    final alerts = <Alert>[];
    final today = _day(input.now);

    for (final district in input.districts) {
      final bins = input.bins
          .where((bin) => bin.districtId == district.id && bin.status.isWorking)
          .toList();
      if (bins.isEmpty) continue;

      double weekKg(List<Reading> readings, int week) => readings
          .where((r) => _ageInDays(today, r.date) ~/ 7 == week && _ageInDays(today, r.date) < 35)
          .fold(0.0, (sum, r) => sum + r.totalKg);

      final lastWeek = <double>[];
      final previous = List.generate(4, (_) => <double>[]);
      var binsThatDropped = 0;
      for (final bin in bins) {
        final readings = input.readingsByBin[bin.id] ?? const <Reading>[];
        final binLast = weekKg(readings, 0);
        final binPrevious = [for (var week = 1; week <= 4; week++) weekKg(readings, week)];
        lastWeek.add(binLast);
        for (var week = 0; week < 4; week++) {
          previous[week].add(binPrevious[week]);
        }
        final binBaseline = binPrevious.reduce((a, b) => a + b) / 4;
        if (collectionDrop.drop(lastWeekKg: binLast, baselineKg: binBaseline) >
            collectionDrop.alertDrop) {
          binsThatDropped++;
        }
      }

      final hit = collectionDrop.evaluate(
        lastWeekKg: lastWeek.reduce((a, b) => a + b),
        previousWeeksKg: [for (final week in previous) week.reduce((a, b) => a + b)],
        binCount: bins.length,
        binsThatDropped: binsThatDropped,
      );
      if (hit == null) continue;

      alerts.add(Alert(
        id: 'low:${district.id}:${_weekKey(input.now)}',
        title: 'Coleta abaixo do esperado em ${district.name}',
        type: AlertType.lowCollection,
        severity: hit.severity,
        status: AlertStatus.open,
        confidence: hit.confidence,
        createdAt: input.now,
        location: district.name,
        detected: 'O volume coletado nos últimos 7 dias caiu '
            '${Formatters.decimal(hit.dropPercent)}% em relação à média das 4 semanas anteriores.',
        evidence: _districtDailyKg(bins, input.readingsByBin, today),
        evidenceLabel: 'Kg coletados por dia no distrito, nos últimos 7 dias',
        rule: collectionDrop.ruleText,
        confidenceReason: '$binsThatDropped de ${bins.length} lixeiras do distrito também '
            'tiveram queda, então ${hit.confidence == Confidence.low ? 'a queda pode vir de poucas lixeiras' : 'a queda aparece em mais de uma lixeira'}.',
        limitations: 'A queda pode ser por chuva forte ou por menos pessoas circulando.',
        suggestedAction: 'Verifique se as lixeiras estão acessíveis e bem sinalizadas.',
      ));
    }
    return alerts;
  }

  // ---------------------------------------------------- demanda sem cobertura

  List<Alert> _coverageAlerts(AlertEngineInput input) {
    final alerts = <Alert>[];

    for (final district in input.districts) {
      final working = input.bins
          .where((bin) => bin.districtId == district.id && bin.status.isWorking)
          .length;
      final hit = coverage.evaluate(demandIndex: district.demandIndex, workingBins: working);
      if (hit == null) continue;

      alerts.add(Alert(
        id: 'coverage:${district.id}',
        title: 'Demanda alta com poucas lixeiras em ${district.name}',
        type: AlertType.lowCoverage,
        severity: hit.severity,
        status: AlertStatus.open,
        confidence: Confidence.medium,
        createdAt: input.now,
        location: district.name,
        detected: 'O índice de demanda do distrito é ${district.demandIndex}, mas só '
            '${working == 1 ? 'há 1 lixeira funcionando' : 'há $working lixeiras funcionando'}.',
        evidence: [for (final value in district.history) value.toDouble()],
        evidenceLabel: 'Índice de demanda nas últimas semanas',
        rule: coverage.ruleText,
        confidenceReason: 'O índice de demanda é uma estimativa e se manteve alto nas últimas semanas.',
        limitations: 'O índice não considera o espaço disponível nem a distância entre as lixeiras.',
        suggestedAction: 'Avalie instalar ou reativar lixeiras nos pontos de maior descarte do distrito.',
      ));
    }
    return alerts;
  }

  // ------------------------------------------------------------------ apoio

  List<double> _lastSevenDays(List<Reading> readings, double Function(Reading) value) =>
      [for (final reading in readings.take(7).toList().reversed) value(reading)];

  List<double> _districtDailyKg(
    List<Bin> bins,
    Map<String, List<Reading>> readingsByBin,
    DateTime today,
  ) {
    return [
      for (var back = 6; back >= 0; back--)
        bins.fold(0.0, (sum, bin) {
          final readings = readingsByBin[bin.id] ?? const <Reading>[];
          return sum +
              readings
                  .where((r) => _ageInDays(today, r.date) == back)
                  .fold(0.0, (s, r) => s + r.totalKg);
        }),
    ];
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);

  int _ageInDays(DateTime today, DateTime date) => today.difference(date).inDays;

  String _ymd(DateTime value) =>
      '${value.year}${value.month.toString().padLeft(2, '0')}${value.day.toString().padLeft(2, '0')}';

  /// Semana do ano, para o alerta valer durante a semana inteira.
  String _weekKey(DateTime value) {
    final week = value.difference(DateTime(value.year, 1, 1)).inDays ~/ 7 + 1;
    return '${value.year}-W${week.toString().padLeft(2, '0')}';
  }
}
