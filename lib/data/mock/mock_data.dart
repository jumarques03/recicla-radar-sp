import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/mock/simulation_config.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/disposal_point.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';

/// Dados simulados da cidade de São Paulo. Tudo é gerado de forma
/// determinística (mesma semente), então o app sempre mostra os mesmos números.
///
/// Os nomes dos lugares são reais, mas as posições são aproximadas e a
/// quantidade de lixo de cada ponto é inventada.
abstract final class MockData {
  /// Dias de leitura gerados por lixeira (cobre o período atual + o anterior).
  static const int readingDays = 180;

  static final DateTime now = DateTime.now();

  static final List<DisposalPoint> disposalPoints = _buildPoints();
  static final List<District> districts = _buildDistricts();
  static final _World _world = _buildWorld();
  static List<Bin> get bins => _world.bins;

  /// Leituras da mais recente (índice 0) para a mais antiga.
  static Map<String, List<Reading>> get readingsByBin => _world.readings;
  static final List<Alert> alerts = _buildAlerts();

  // id, nome, latitude e longitude do centro aproximado do distrito.
  static const List<(String, String, double, double)> _districtSeeds = [
    ('jabaquara', 'Jabaquara', -23.6486, -46.6406),
    ('pinheiros', 'Pinheiros', -23.5670, -46.7020),
    ('mooca', 'Mooca', -23.5600, -46.5990),
    ('se', 'Sé', -23.5505, -46.6333),
    ('santo-amaro', 'Santo Amaro', -23.6537, -46.7090),
    ('itaquera', 'Itaquera', -23.5400, -46.4560),
    ('penha', 'Penha', -23.5280, -46.5440),
    ('santana', 'Santana', -23.5000, -46.6250),
    ('lapa', 'Lapa', -23.5220, -46.7040),
    ('vila-mariana', 'Vila Mariana', -23.5890, -46.6340),
    ('butanta', 'Butantã', -23.5710, -46.7260),
    ('campo-limpo', 'Campo Limpo', -23.6240, -46.7570),
    ('capao-redondo', 'Capão Redondo', -23.6700, -46.7800),
    ('brasilandia', 'Brasilândia', -23.4600, -46.6900),
  ];

  // distrito, nome do ponto, latitude, longitude, intensidade (1 a 10).
  static const List<(String, String, double, double, int)> _pointSeeds = [
    ('jabaquara', 'Terminal Jabaquara', -23.6679, -46.6410, 9),
    ('jabaquara', 'Feira livre do Jabaquara', -23.6420, -46.6430, 6),
    ('jabaquara', 'Av. Engenheiro Armando de Arruda Pereira', -23.6400, -46.6500, 5),
    ('pinheiros', 'Largo da Batata', -23.5662, -46.6913, 9),
    ('pinheiros', 'Praça Benedito Calixto', -23.5630, -46.6836, 7),
    ('pinheiros', 'Av. Faria Lima', -23.5700, -46.6930, 8),
    ('mooca', 'Estação Mooca', -23.5586, -46.5997, 6),
    ('mooca', 'Rua da Mooca', -23.5600, -46.5990, 6),
    ('mooca', 'Feira da Mooca', -23.5575, -46.6010, 5),
    ('se', 'Praça da Sé', -23.5505, -46.6333, 10),
    ('se', 'Mercado Municipal', -23.5416, -46.6297, 9),
    ('se', 'Rua 25 de Março', -23.5440, -46.6310, 10),
    ('se', 'Parque Dom Pedro II', -23.5430, -46.6280, 7),
    ('santo-amaro', 'Terminal Santo Amaro', -23.6560, -46.7100, 8),
    ('santo-amaro', 'Largo Treze de Maio', -23.6537, -46.7090, 7),
    ('itaquera', 'Terminal Itaquera', -23.5400, -46.4710, 8),
    ('itaquera', 'Arena Corinthians', -23.5453, -46.4742, 7),
    ('itaquera', 'Parque do Carmo', -23.5793, -46.4640, 5),
    ('penha', 'Largo do Rosário da Penha', -23.5280, -46.5440, 6),
    ('penha', 'Rua Penha de França', -23.5230, -46.5400, 5),
    ('santana', 'Terminal Santana', -23.4990, -46.6250, 7),
    ('santana', 'Rua Voluntários da Pátria', -23.5050, -46.6280, 6),
    ('lapa', 'Largo da Lapa', -23.5220, -46.7040, 7),
    ('lapa', 'Terminal Lapa', -23.5223, -46.7020, 7),
    ('lapa', 'Rua Clélia', -23.5260, -46.7080, 5),
    ('vila-mariana', 'Parque Ibirapuera', -23.5874, -46.6576, 9),
    ('vila-mariana', 'Metrô Vila Mariana', -23.5890, -46.6340, 6),
    ('vila-mariana', 'Rua Domingos de Morais', -23.5880, -46.6370, 5),
    ('butanta', 'Cidade Universitária (USP)', -23.5600, -46.7300, 7),
    ('butanta', 'Av. Vital Brasil', -23.5710, -46.7260, 5),
    ('campo-limpo', 'Terminal Campo Limpo', -23.6240, -46.7570, 6),
    ('campo-limpo', 'Largo do Campo Limpo', -23.6260, -46.7600, 4),
    ('capao-redondo', 'Terminal Capão Redondo', -23.6590, -46.7790, 5),
    ('capao-redondo', 'Estrada de Itapecerica', -23.6700, -46.7800, 4),
    ('brasilandia', 'Largo da Brasilândia', -23.4600, -46.6900, 4),
    ('brasilandia', 'Av. Elísio Teixeira Leite', -23.4630, -46.6930, 4),
  ];

  static String _districtName(String id) =>
      _districtSeeds.firstWhere((seed) => seed.$1 == id).$2;

  static List<DisposalPoint> _buildPoints() {
    return [
      for (var i = 0; i < _pointSeeds.length; i++)
        DisposalPoint(
          id: 'pt-${(i + 1).toString().padLeft(2, '0')}',
          name: _pointSeeds[i].$2,
          districtId: _pointSeeds[i].$1,
          position: LatLng(_pointSeeds[i].$3, _pointSeeds[i].$4),
          intensity: _pointSeeds[i].$5,
        ),
    ];
  }

  /// A demanda de cada distrito vem dos pontos de descarte dele: soma das
  /// intensidades, com raiz quadrada para os distritos menores não ficarem
  /// todos perto de zero. O distrito com mais descarte vale 100.
  static List<District> _buildDistricts() {
    final random = Random(7);
    final totals = <String, int>{for (final seed in _districtSeeds) seed.$1: 0};
    for (final point in disposalPoints) {
      totals[point.districtId] = totals[point.districtId]! + point.intensity;
    }
    final maxTotal = totals.values.reduce(max);

    return [
      for (final seed in _districtSeeds)
        _buildDistrict(seed, totals[seed.$1]! / maxTotal, random),
    ];
  }

  static District _buildDistrict(
    (String, String, double, double) seed,
    double share,
    Random random,
  ) {
    final index = (100 * sqrt(share)).round().clamp(5, 100);
    return District(
      id: seed.$1,
      name: seed.$2,
      position: LatLng(seed.$3, seed.$4),
      demandIndex: index,
      binCount: bins.where((bin) => bin.districtId == seed.$1).length,
      history: [
        for (var week = 0; week < 7; week++) (index + random.nextInt(25) - 12).clamp(5, 100),
        index,
      ],
    );
  }

  static _World _buildWorld() {
    final random = Random(42);

    // Uma lixeira por ponto; os pontos mais movimentados ganham uma segunda.
    final specs = <(DisposalPoint, int)>[
      for (final point in disposalPoints) ...[
        (point, 1),
        if (point.intensity >= SimulationConfig.busyPointIntensity) (point, 2),
      ],
    ];

    // Pontos mais movimentados enchem mais rápido.
    final fills = [
      for (final spec in specs)
        (18 + spec.$1.intensity * 5 + random.nextInt(25) - 12).clamp(8, 89),
    ];

    // As três lixeiras dos pontos mais movimentados já estão quase cheias.
    final busiest = [for (var i = 0; i < specs.length; i++) i]..sort((a, b) {
        final byIntensity = specs[b].$1.intensity.compareTo(specs[a].$1.intensity);
        return byIntensity != 0 ? byIntensity : a.compareTo(b);
      });
    const nearlyFull = [96, 91, 88];
    for (var i = 0; i < nearlyFull.length; i++) {
      fills[busiest[i]] = nearlyFull[i];
    }
    final keepFillStatus = busiest.take(nearlyFull.length).toSet();

    final readings = <String, List<Reading>>{};
    final bins = [
      for (var i = 0; i < specs.length; i++)
        _buildBin(
          index: i,
          point: specs[i].$1,
          number: specs[i].$2,
          fill: fills[i],
          keepFillStatus: keepFillStatus.contains(i),
          random: random,
          readingsOut: readings,
        ),
    ];
    return _World(bins, Map.unmodifiable(readings));
  }

  static Bin _buildBin({
    required int index,
    required DisposalPoint point,
    required int number,
    required int fill,
    required bool keepFillStatus,
    required Random random,
    required Map<String, List<Reading>> readingsOut,
  }) {
    final statusFromFill = fill >= 90
        ? BinStatus.full
        : fill >= 70
            ? BinStatus.almostFull
            : BinStatus.operating;
    final status = keepFillStatus
        ? statusFromFill
        : switch (index) {
            6 => BinStatus.offline,
            _ when index % 11 == 4 => BinStatus.maintenance,
            _ => statusFromFill,
          };

    final id = 'bin-${(index + 1).toString().padLeft(2, '0')}';
    final readings = _readingsFor(id, fill, point.intensity, random);
    final byMaterial = <WasteMaterial, double>{
      for (final material in WasteMaterial.values)
        material: readings
            .take(30)
            .fold(0.0, (sum, reading) => sum + (reading.kgByMaterial[material] ?? 0)),
    };
    final hoursSinceCollection = max(2, (fill / (10 + random.nextInt(8))) * 24).round();
    final isBusy = point.intensity >= SimulationConfig.busyPointIntensity;
    final side = number == 1 ? 1 : -1;
    final districtName = _districtName(point.districtId);

    readingsOut[id] = readings;
    return Bin(
      id: id,
      name: 'Lixeira ${point.name}${isBusy ? ' 0$number' : ''}',
      address: '${point.name}, $districtName',
      districtId: point.districtId,
      districtName: districtName,
      pointId: point.id,
      pointName: point.name,
      // Até ~50 m do ponto de descarte.
      position: LatLng(
        point.position.latitude + side * (0.0002 + random.nextDouble() * 0.0002),
        point.position.longitude - side * (0.0002 + random.nextDouble() * 0.0002),
      ),
      fillPercent: fill,
      status: status,
      totalKg: byMaterial.values.fold(0, (sum, kg) => sum + kg),
      kgByMaterial: byMaterial,
      lastCollection: now.subtract(Duration(hours: hoursSinceCollection)),
    );
  }

  /// Quanto cada lixeira coleta depende da intensidade do ponto onde está.
  static List<Reading> _readingsFor(
    String binId,
    int currentFill,
    int intensity,
    Random random,
  ) {
    final perDay = 10 + random.nextInt(8);
    final scale = (0.25 + intensity * 0.12) * (0.85 + random.nextDouble() * 0.3);
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
    final working = bins.where((bin) => bin.status.isWorking).toList();
    final byFill = [...working]..sort((a, b) => b.fillPercent.compareTo(a.fillPercent));
    final offline = bins.firstWhere((bin) => bin.status == BinStatus.offline);
    final anomaly = working.firstWhere(
      (bin) => bin.status == BinStatus.operating && !byFill.take(6).contains(bin),
    );
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
        location: bin.address,
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
        location: offline.address,
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
        location: anomaly.address,
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
