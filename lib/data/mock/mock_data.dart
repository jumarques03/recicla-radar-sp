import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';

/// Dados simulados da cidade de São Paulo. Tudo é gerado de forma
/// determinística (mesma semente), então o app sempre mostra os mesmos números.
abstract final class MockData {
  /// Dias de leitura gerados por lixeira (cobre o período atual + o anterior).
  static const int readingDays = 180;

  static final DateTime now = DateTime.now();

  static final List<District> districts = _buildDistricts();
  static final _World _world = _buildWorld();
  static List<Bin> get bins => _world.bins;

  /// Leituras da mais recente (índice 0) para a mais antiga.
  static Map<String, List<Reading>> get readingsByBin => _world.readings;
  static final List<Alert> alerts = _buildAlerts();

  // id, nome, latitude, longitude, índice de demanda, rua de referência.
  static const List<(String, String, double, double, int, String)> _seeds = [
    ('jabaquara', 'Jabaquara', -23.6486, -46.6406, 82, 'Av. Engenheiro Armando de Arruda Pereira'),
    ('pinheiros', 'Pinheiros', -23.5670, -46.7020, 74, 'Rua dos Pinheiros'),
    ('mooca', 'Mooca', -23.5600, -46.5990, 68, 'Rua da Mooca'),
    ('se', 'Sé', -23.5505, -46.6333, 91, 'Praça da Sé'),
    ('santo-amaro', 'Santo Amaro', -23.6537, -46.7090, 63, 'Av. Adolfo Pinheiro'),
    ('itaquera', 'Itaquera', -23.5400, -46.4560, 47, 'Av. Radial Leste'),
    ('penha', 'Penha', -23.5280, -46.5440, 55, 'Rua Penha de França'),
    ('santana', 'Santana', -23.5000, -46.6250, 52, 'Av. Cruzeiro do Sul'),
    ('lapa', 'Lapa', -23.5220, -46.7040, 71, 'Rua Clélia'),
    ('vila-mariana', 'Vila Mariana', -23.5890, -46.6340, 77, 'Rua Domingos de Morais'),
    ('butanta', 'Butantã', -23.5710, -46.7260, 38, 'Av. Vital Brasil'),
    ('campo-limpo', 'Campo Limpo', -23.6240, -46.7570, 33, 'Estrada do Campo Limpo'),
    ('capao-redondo', 'Capão Redondo', -23.6700, -46.7800, 29, 'Estrada de Itapecerica'),
    ('brasilandia', 'Brasilândia', -23.4600, -46.6900, 25, 'Av. Elísio Teixeira Leite'),
  ];

  static List<District> _buildDistricts() {
    final random = Random(7);
    return [
      for (final seed in _seeds)
        District(
          id: seed.$1,
          name: seed.$2,
          position: LatLng(seed.$3, seed.$4),
          demandIndex: seed.$5,
          binCount: _binSeedsFor(seed.$1).length,
          history: [
            for (var week = 0; week < 7; week++)
              (seed.$5 + random.nextInt(25) - 12).clamp(5, 100),
            seed.$5,
          ],
        ),
    ];
  }

  static const int _binTotal = 20;

  static List<int> _binSeedsFor(String districtId) {
    final index = _seeds.indexWhere((seed) => seed.$1 == districtId);
    return [for (var i = 0; i < _binTotal; i++) if (i % _seeds.length == index) i];
  }

  static _World _buildWorld() {
    final random = Random(42);
    final readings = <String, List<Reading>>{};
    final bins = [
      for (var i = 0; i < _binTotal; i++)
        _buildBin(i, _seeds[i % _seeds.length], random, readings),
    ];
    return _World(bins, Map.unmodifiable(readings));
  }

  static Bin _buildBin(
    int index,
    (String, String, double, double, int, String) seed,
    Random random,
    Map<String, List<Reading>> readingsOut,
  ) {
    final fill = switch (index) {
      0 => 96,
      1 => 91,
      9 => 88,
      _ => 12 + random.nextInt(78),
    };
    final status = switch (index) {
      3 || 10 || 17 => BinStatus.maintenance,
      6 => BinStatus.offline,
      _ => fill >= 90
          ? BinStatus.full
          : fill >= 70
              ? BinStatus.almostFull
              : BinStatus.operating,
    };
    final number = index ~/ _seeds.length + 1;
    final id = 'bin-${(index + 1).toString().padLeft(2, '0')}';
    final readings = _readingsFor(id, fill, random);
    final byMaterial = <WasteMaterial, double>{
      for (final material in WasteMaterial.values)
        material: readings
            .take(30)
            .fold(0.0, (sum, reading) => sum + (reading.kgByMaterial[material] ?? 0)),
    };
    final hoursSinceCollection = max(2, (fill / (10 + random.nextInt(8))) * 24).round();

    readingsOut[id] = readings;
    return Bin(
      id: id,
      name: 'Lixeira ${seed.$2} ${number.toString().padLeft(2, '0')}',
      address: '${seed.$6}, ${100 + random.nextInt(900)} - ${seed.$2}',
      districtId: seed.$1,
      districtName: seed.$2,
      position: LatLng(
        seed.$3 + (random.nextDouble() - 0.5) * 0.016,
        seed.$4 + (random.nextDouble() - 0.5) * 0.016,
      ),
      fillPercent: fill,
      status: status,
      totalKg: byMaterial.values.fold(0, (sum, kg) => sum + kg),
      kgByMaterial: byMaterial,
      lastCollection: now.subtract(Duration(hours: hoursSinceCollection)),
    );
  }

  static List<Reading> _readingsFor(String binId, int currentFill, Random random) {
    final perDay = 10 + random.nextInt(8);
    final scale = 0.6 + random.nextDouble() * 0.9;
    return [
      for (var day = 0; day < readingDays; day++)
        Reading(
          binId: binId,
          date: DateTime(now.year, now.month, now.day).subtract(Duration(days: day)),
          fillPercent: (((currentFill - day * perDay) % 100) + 100).round() % 100,
          kgByMaterial: {
            WasteMaterial.plastic: (3 + random.nextDouble() * 4) * scale,
            WasteMaterial.glass: (1.5 + random.nextDouble() * 3) * scale,
            WasteMaterial.paper: (2.5 + random.nextDouble() * 3.5) * scale,
            WasteMaterial.metal: (0.6 + random.nextDouble() * 1.4) * scale,
          },
        ),
    ];
  }

  static List<Alert> _buildAlerts() {
    final byFill = [...bins]..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
    final offline = bins.firstWhere((bin) => bin.status == BinStatus.offline);
    final anomaly = bins.firstWhere((bin) => bin.id == 'bin-05');
    final lowCollection = districts.firstWhere((district) => district.id == 'itaquera');

    List<double> fillTrend(Bin bin) => [
          for (final reading in readingsByBin[bin.id]!.take(7).toList().reversed)
            reading.fillPercent.toDouble(),
        ];

    Alert fillAlert(
      String id,
      Bin bin,
      int hours,
      AlertSeverity severity,
      Confidence confidence,
      AlertStatus status,
      int minutesAgo,
    ) {
      return Alert(
        id: id,
        title: '${bin.name} deve encher em $hours h',
        type: AlertType.fillPrediction,
        severity: severity,
        status: status,
        confidence: confidence,
        createdAt: now.subtract(Duration(minutes: minutesAgo)),
        location: '${bin.districtName} · ${bin.address}',
        binId: bin.id,
        detected:
            'A lixeira está com ${bin.fillPercent}% de enchimento e enche cerca de 2% por hora. '
            'No ritmo atual, ela fica cheia em aproximadamente $hours horas.',
        evidence: fillTrend(bin),
        evidenceLabel: 'Enchimento (%) nos últimos 7 dias',
        rule: 'Alerta quando o enchimento passa de 80% ou quando a previsão de lotação é menor que 24 horas.',
        confidenceReason: confidence == Confidence.high
            ? 'O sensor enviou leituras todos os dias e o ritmo de enchimento é parecido com o das últimas semanas.'
            : 'Algumas leituras recentes variaram bastante, então a previsão pode mudar.',
        limitations:
            'A previsão não considera feriados, eventos na região nem coletas extras já programadas.',
        suggestedAction:
            'Priorize a coleta desta lixeira ainda hoje. Se já foi coletada, marque como resolvido.',
      );
    }

    return [
      fillAlert('alert-01', byFill[0], 3, AlertSeverity.critical, Confidence.high, AlertStatus.open, 25),
      fillAlert('alert-02', byFill[1], 5, AlertSeverity.critical, Confidence.high, AlertStatus.inAnalysis, 70),
      fillAlert('alert-03', byFill[2], 9, AlertSeverity.high, Confidence.medium, AlertStatus.open, 140),
      fillAlert('alert-04', byFill[3], 14, AlertSeverity.medium, Confidence.medium, AlertStatus.open, 380),
      Alert(
        id: 'alert-05',
        title: '${offline.name} está sem sinal',
        type: AlertType.offline,
        severity: AlertSeverity.high,
        status: AlertStatus.open,
        confidence: Confidence.high,
        createdAt: now.subtract(const Duration(hours: 18)),
        location: '${offline.districtName} · ${offline.address}',
        binId: offline.id,
        detected: 'O sensor não envia leituras há 18 horas.',
        evidence: [for (var i = 0; i < 7; i++) i < 5 ? 1.0 : 0.0],
        evidenceLabel: 'Leituras recebidas por dia (1 = recebeu)',
        rule: 'Alerta quando não chega nenhuma leitura por mais de 12 horas.',
        confidenceReason: 'A falha de comunicação é confirmada pela ausência total de leituras.',
        limitations: 'Não sabemos se o problema é a bateria, o chip ou a lixeira.',
        suggestedAction: 'Envie um fiscal para conferir o equipamento e registre uma vistoria.',
      ),
      Alert(
        id: 'alert-06',
        title: 'Aumento incomum de vidro em ${anomaly.name}',
        type: AlertType.anomaly,
        severity: AlertSeverity.medium,
        status: AlertStatus.open,
        confidence: Confidence.low,
        createdAt: now.subtract(const Duration(hours: 9)),
        location: '${anomaly.districtName} · ${anomaly.address}',
        binId: anomaly.id,
        detected: 'A quantidade de vidro foi 2,4 vezes maior que a média dos últimos 30 dias.',
        evidence: const [3.1, 2.8, 3.4, 2.9, 3.0, 7.4, 7.1],
        evidenceLabel: 'Vidro coletado (kg) nos últimos 7 dias',
        rule: 'Alerta quando um material passa de 2 vezes a média de 30 dias.',
        confidenceReason: 'Foram só 2 dias fora do padrão. Pode ser um evento pontual.',
        limitations: 'Não sabemos se houve festa, obra ou erro de leitura na região.',
        suggestedAction: 'Acompanhe por mais 2 dias antes de tomar qualquer providência.',
      ),
      Alert(
        id: 'alert-07',
        title: 'Coleta abaixo do esperado em ${lowCollection.name}',
        type: AlertType.lowCollection,
        severity: AlertSeverity.low,
        status: AlertStatus.open,
        confidence: Confidence.medium,
        createdAt: now.subtract(const Duration(days: 1, hours: 3)),
        location: lowCollection.name,
        detected: 'O volume coletado caiu 18% em relação às últimas 4 semanas.',
        evidence: const [410, 395, 402, 388, 361, 340, 330],
        evidenceLabel: 'Kg coletados por dia nos últimos 7 dias',
        rule: 'Alerta quando o volume cai mais de 15% contra a média de 4 semanas.',
        confidenceReason: 'A queda foi gradual e aparece em mais de uma lixeira.',
        limitations: 'A queda pode ser por chuva forte ou por menos pessoas circulando.',
        suggestedAction: 'Verifique se as lixeiras estão acessíveis e bem sinalizadas.',
      ),
      fillAlert('alert-08', byFill[4], 18, AlertSeverity.medium, Confidence.high, AlertStatus.resolved, 2000),
      fillAlert('alert-09', byFill[5], 20, AlertSeverity.low, Confidence.low, AlertStatus.discarded, 2600),
    ];
  }
}

class _World {
  const _World(this.bins, this.readings);

  final List<Bin> bins;
  final Map<String, List<Reading>> readings;
}
