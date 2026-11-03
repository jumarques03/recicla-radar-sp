import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/data/models/inspection.dart';
import 'package:recicla_radar_sp/data/models/overview_summary.dart';
import 'package:recicla_radar_sp/data/models/reading.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';

abstract interface class BinRepository {
  Future<List<Bin>> fetchBins();

  /// Leituras diárias, da mais recente para a mais antiga.
  Future<List<Reading>> fetchReadings(String binId, {int days = 30});
}

abstract interface class DistrictRepository {
  Future<List<District>> fetchDistricts();
}

abstract interface class AlertRepository {
  Future<List<Alert>> fetchAlerts();

  Future<Alert> updateStatus(String alertId, AlertStatus status);
}

abstract interface class InspectionRepository {
  Future<void> submit(Inspection inspection);
}

abstract interface class OverviewRepository {
  Future<OverviewSummary> fetchSummary({required int days, WasteMaterial? material});
}
