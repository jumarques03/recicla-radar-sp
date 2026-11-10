import 'dart:math';

import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/mock/district_seeds.dart';
import 'package:recicla_radar_sp/data/mock/simulation_config.dart';
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

  static String _districtName(String id) =>
      districtSeeds.firstWhere((seed) => '${seed.$1}' == id).$2;

  /// Pontos de descarte de todos os distritos (definidos em `district_seeds.dart`).
  static List<DisposalPoint> _buildPoints() {
    final points = <DisposalPoint>[];
    for (final seed in districtSeeds) {
      for (final point in seed.$5) {
        points.add(
          DisposalPoint(
            id: 'pt-${(points.length + 1).toString().padLeft(3, '0')}',
            name: point.$1,
            districtId: '${seed.$1}',
            position: LatLng(point.$2, point.$3),
            intensity: point.$4,
          ),
        );
      }
    }
    return points;
  }

  /// A demanda de cada distrito vem dos pontos de descarte dele. O índice é a
  /// posição do distrito entre os 96, pela soma das intensidades dos pontos:
  /// 100 para o que mais descarta e perto de 0 para o que menos descarta.
  static List<District> _buildDistricts() {
    final random = Random(7);
    final totals = <String, int>{for (final seed in districtSeeds) '${seed.$1}': 0};
    for (final point in disposalPoints) {
      totals[point.districtId] = totals[point.districtId]! + point.intensity;
    }
    final values = totals.values.toList();

    return [
      for (final seed in districtSeeds)
        _buildDistrict(seed, _positionIndex(totals['${seed.$1}']!, values), random),
    ];
  }

  /// Posição relativa (0 a 100). Distritos empatados ficam com o mesmo valor.
  static int _positionIndex(int total, List<int> all) {
    final below = all.where((value) => value < total).length;
    final equal = all.where((value) => value == total).length;
    final averageRank = below + (equal - 1) / 2;
    return (100 * averageRank / (all.length - 1)).round().clamp(5, 100);
  }

  static District _buildDistrict(DistrictSeed seed, int index, Random random) {
    final id = '${seed.$1}';
    return District(
      id: id,
      name: seed.$2,
      position: LatLng(seed.$3, seed.$4),
      demandIndex: index,
      binCount: bins.where((bin) => bin.districtId == id).length,
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

    // As lixeiras dos pontos mais movimentados já estão quase cheias.
    final busiest = [for (var i = 0; i < specs.length; i++) i]..sort((a, b) {
        final byIntensity = specs[b].$1.intensity.compareTo(specs[a].$1.intensity);
        return byIntensity != 0 ? byIntensity : a.compareTo(b);
      });
    const nearlyFull = [98, 93, 88, 84, 82, 79];
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

  /// Aumentos incomuns de um material, por índice da lixeira:
  /// (material, dias seguidos, multiplicador do volume).
  static const Map<int, (WasteMaterial, int, double)> _anomalies = {
    20: (WasteMaterial.glass, 2, 2.6),
    55: (WasteMaterial.plastic, 4, 2.3),
    120: (WasteMaterial.metal, 6, 3.4),
  };

  /// Distritos em que a coleta dos últimos 7 dias caiu (multiplicador do volume).
  static const Map<String, double> _collectionDrops = {
    'Itaquera': 0.70,
    'Penha': 0.80,
    'Santana': 0.62,
  };

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
            _ when index % 59 == 6 => BinStatus.offline,
            _ when index % 11 == 4 => BinStatus.maintenance,
            _ => statusFromFill,
          };

    final id = 'bin-${(index + 1).toString().padLeft(2, '0')}';
    final districtName = _districtName(point.districtId);

    // Pontos mais movimentados enchem mais rápido (pontos percentuais por dia).
    final fillPerDay = (5 + point.intensity * 1.6 + random.nextInt(5)).round();
    // A lixeira foi esvaziada quando estava em 0%, há fill / ritmo dias.
    final hoursSinceCollection = max(2, (fill / fillPerDay * 24).round());
    // Lixeiras sem sinal pararam de enviar leituras há mais de 12 horas.
    final silence = status == BinStatus.offline
        ? Duration(hours: 14 + random.nextInt(40))
        : Duration(minutes: 5 + random.nextInt(50));
    final lastSignalAt = now.subtract(silence);

    final readings = _readingsFor(
      binId: id,
      currentFill: fill,
      fillPerDay: fillPerDay,
      intensity: point.intensity,
      lastSignalAt: lastSignalAt,
      anomaly: _anomalies[index],
      collectionFactor: _collectionDrops[districtName] ?? 1,
      random: random,
    );
    final byMaterial = <WasteMaterial, double>{
      for (final material in WasteMaterial.values)
        material: readings
            .take(30)
            .fold(0.0, (sum, reading) => sum + (reading.kgByMaterial[material] ?? 0)),
    };
    final isBusy = point.intensity >= SimulationConfig.busyPointIntensity;
    final side = number == 1 ? 1 : -1;

    readingsOut[id] = readings;
    return Bin(
      id: id,
      name: 'Lixeira ${point.name}${isBusy ? ' 0$number' : ''}',
      address: point.name.contains(districtName) ? point.name : '${point.name}, $districtName',
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
      lastSignalAt: lastSignalAt,
    );
  }

  /// Leituras diárias, da mais recente para a mais antiga. O enchimento sobe
  /// [fillPerDay] pontos por dia e cai a ~0% a cada coleta; o volume de cada
  /// material depende da intensidade do ponto.
  static List<Reading> _readingsFor({
    required String binId,
    required int currentFill,
    required int fillPerDay,
    required int intensity,
    required DateTime lastSignalAt,
    required (WasteMaterial, int, double)? anomaly,
    required double collectionFactor,
    required Random random,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final lastDay = DateTime(lastSignalAt.year, lastSignalAt.month, lastSignalAt.day);
    // Quantos dias sem nenhuma leitura (só acontece com lixeiras sem sinal).
    final firstDay = today.difference(lastDay).inDays;
    final scale = (0.25 + intensity * 0.12) * (0.85 + random.nextDouble() * 0.3);

    return [
      for (var day = firstDay; day < readingDays; day++)
        () {
          final daysBack = day - firstDay;
          final fill = daysBack == 0
              ? currentFill
              : (((currentFill - daysBack * fillPerDay) % 100) + random.nextInt(7) - 3)
                  .clamp(0, 99);
          // Quedas de coleta valem para a última semana; aumentos, para os últimos dias.
          final factor = day < 7 ? collectionFactor : 1.0;

          // [min] e [spread] definem o volume normal do dia. Nos dias de aumento
          // incomum o volume fica perto da média, multiplicado pelo fator.
          double kg(WasteMaterial material, double min, double spread) {
            final draw = random.nextDouble();
            final boosted = anomaly != null && anomaly.$1 == material && day < anomaly.$2;
            final base = boosted
                ? (min + spread / 2) * (0.92 + 0.16 * draw) * anomaly.$3
                : min + spread * draw;
            return base * scale * factor;
          }

          return Reading(
            binId: binId,
            date: today.subtract(Duration(days: day)),
            fillPercent: fill,
            kgByMaterial: {
              WasteMaterial.plastic: kg(WasteMaterial.plastic, 3, 4),
              WasteMaterial.glass: kg(WasteMaterial.glass, 1.5, 3),
              WasteMaterial.paper: kg(WasteMaterial.paper, 2.5, 3.5),
              WasteMaterial.metal: kg(WasteMaterial.metal, 0.6, 1.4),
            },
          );
        }(),
    ];
  }
}

class _World {
  const _World(this.bins, this.readings);

  final List<Bin> bins;
  final Map<String, List<Reading>> readings;
}
