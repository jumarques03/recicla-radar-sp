import 'package:recicla_radar_sp/data/models/waste_material.dart';

/// Leitura diária de uma lixeira.
class Reading {
  const Reading({
    required this.binId,
    required this.date,
    required this.fillPercent,
    required this.kgByMaterial,
  });

  final String binId;
  final DateTime date;
  final int fillPercent;
  final Map<WasteMaterial, double> kgByMaterial;

  double get totalKg => kgByMaterial.values.fold(0, (sum, kg) => sum + kg);
}
