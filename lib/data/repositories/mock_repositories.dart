import 'package:recicla_radar_sp/data/mock/mock_data.dart';
import 'package:recicla_radar_sp/data/mock/simulation_config.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/disposal_point.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/models/overview_summary.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';
import 'package:recicla_radar_sp/data/repositories/data_repositories.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';

Future<void> _simulateNetwork() =>
    Future<void>.delayed(const Duration(milliseconds: 400));

class MockBinRepository implements BinRepository {
  @override
  Future<List<Bin>> fetchBins() async {
    await _simulateNetwork();
    return MockData.bins;
  }

  @override
  Future<List<DisposalPoint>> fetchDisposalPoints() async {
    await _simulateNetwork();
    return MockData.disposalPoints;
  }

  @override
  Future<List<Reading>> fetchReadings(String binId, {int days = 30}) async {
    await _simulateNetwork();
    final readings = MockData.readingsByBin[binId] ?? const <Reading>[];
    return readings.take(days).toList();
  }
}

class MockDistrictRepository implements DistrictRepository {
  @override
  Future<List<District>> fetchDistricts() async {
    await _simulateNetwork();
    return MockData.districts;
  }
}

class MockInspectionRepository implements InspectionRepository {
  final List<Inspection> submitted = [];

  @override
  Future<void> submit(Inspection inspection) async {
    await _simulateNetwork();
    submitted.add(inspection);
  }
}

/// Soma as leituras simuladas para montar a visão geral de um período.
class MockOverviewRepository implements OverviewRepository {
  @override
  Future<OverviewSummary> fetchSummary({required int days, WasteMaterial? material}) async {
    await _simulateNetwork();
    final materials = material == null ? WasteMaterial.values : [material];
    final readings = MockData.readingsByBin.values.expand((list) => list).toList();

    double sum(Iterable<Reading> items) => items.fold(
          0.0,
          (total, reading) =>
              total +
              materials.fold(0.0, (acc, m) => acc + (reading.kgByMaterial[m] ?? 0)),
        );

    final today = DateTime(MockData.now.year, MockData.now.month, MockData.now.day);
    int daysAgo(Reading reading) => today.difference(reading.date).inDays;

    final current = readings.where((r) => daysAgo(r) < days).toList();
    final previous = readings.where((r) => daysAgo(r) >= days && daysAgo(r) < days * 2);
    final totalKg = sum(current);

    final bins = MockData.bins;
    final working = bins.where((bin) => bin.status.isWorking).length;

    return OverviewSummary(
      days: days,
      totalKg: totalKg,
      previousKg: sum(previous),
      operatingPercent: (working / bins.length * 100).round(),
      divertedKg: totalKg * SimulationConfig.recoveryRate,
      recoveryRate: SimulationConfig.recoveryRate,
      series: _buildSeries(current, days, today, sum),
      seriesUnit: days <= 7 ? 'dia' : 'semana',
      byMaterial: {
        for (final m in WasteMaterial.values)
          m: current.fold(0.0, (acc, r) => acc + (r.kgByMaterial[m] ?? 0)),
      },
    );
  }

  List<SeriesPoint> _buildSeries(
    List<Reading> current,
    int days,
    DateTime today,
    double Function(Iterable<Reading>) sum,
  ) {
    final bucketSize = days <= 7 ? 1 : 7;
    final buckets = days ~/ bucketSize;
    return [
      for (var bucket = buckets - 1; bucket >= 0; bucket--)
        SeriesPoint(
          Formatters.shortDate(today.subtract(Duration(days: (bucket + 1) * bucketSize - 1))),
          sum(current.where((r) {
            final age = today.difference(r.date).inDays;
            return age >= bucket * bucketSize && age < (bucket + 1) * bucketSize;
          })),
        ),
    ];
  }
}
