import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/mock/simulation_config.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/repositories/mock_repositories.dart';

void main() {
  final points = MockData.disposalPoints;
  final bins = MockData.bins;
  const distance = Distance();

  group('pontos de descarte e lixeiras', () {
    test('há vários pontos e mais lixeiras do que a versão inicial (20)', () {
      expect(points.length, greaterThanOrEqualTo(30));
      expect(bins.length, greaterThan(40));
    });

    test('todo ponto tem lixeira, e os mais movimentados têm duas', () {
      for (final point in points) {
        final count = bins.where((bin) => bin.pointId == point.id).length;
        final expected = point.intensity >= SimulationConfig.busyPointIntensity ? 2 : 1;
        expect(count, expected, reason: point.name);
      }
    });

    test('cada lixeira fica a menos de 100 m do seu ponto', () {
      for (final bin in bins) {
        final point = points.firstWhere((p) => p.id == bin.pointId);
        final meters = distance.as(LengthUnit.Meter, point.position, bin.position);
        expect(meters, lessThan(100), reason: bin.name);
      }
    });

    test('lixeiras em pontos mais movimentados coletam mais, em média', () {
      double averageKg(bool busy) {
        final selected = bins.where((bin) {
          final point = points.firstWhere((p) => p.id == bin.pointId);
          return (point.intensity >= SimulationConfig.busyPointIntensity) == busy;
        });
        return selected.fold(0.0, (sum, bin) => sum + bin.totalKg) / selected.length;
      }

      expect(averageKg(true), greaterThan(averageKg(false)));
    });

    test('o cenário tem lixeiras quase cheias e uma sem sinal', () {
      expect(bins.where((bin) => bin.fillPercent >= 88).length, greaterThanOrEqualTo(3));
      expect(bins.any((bin) => bin.status == BinStatus.offline), isTrue);
    });
  });

  group('demanda dos distritos', () {
    test('vem da soma das intensidades dos pontos do distrito', () {
      int total(String districtId) => points
          .where((point) => point.districtId == districtId)
          .fold(0, (sum, point) => sum + point.intensity);

      final byTotal = [...MockData.districts]
        ..sort((a, b) => total(a.id).compareTo(total(b.id)));
      for (var i = 1; i < byTotal.length; i++) {
        expect(byTotal[i].demandIndex, greaterThanOrEqualTo(byTotal[i - 1].demandIndex));
      }
      expect(byTotal.last.demandIndex, 100);
    });

    test('o número de lixeiras do distrito bate com a lista', () {
      for (final district in MockData.districts) {
        final count = bins.where((bin) => bin.districtId == district.id).length;
        expect(district.binCount, count, reason: district.name);
      }
    });
  });

  group('reaproveitamento', () {
    test('a taxa assumida é de 75%', () {
      expect(SimulationConfig.recoveryRate, 0.75);
    });

    test('kg fora do aterro é 75% do coletado', () async {
      final summary = await MockOverviewRepository().fetchSummary(days: 30);
      expect(summary.recoveryRate, 0.75);
      expect(summary.divertedKg, closeTo(summary.totalKg * 0.75, 0.001));
    });
  });
}
