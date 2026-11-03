import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/models/waste_material.dart';

enum BinStatus {
  operating('Operando'),
  almostFull('Quase cheia'),
  full('Cheia'),
  maintenance('Em manutenção'),
  offline('Sem sinal');

  const BinStatus(this.label);
  final String label;

  /// Lixeiras que estão enviando dados e recebendo material.
  bool get isWorking => this != maintenance && this != offline;
}

/// Lixeira inteligente recicladora.
class Bin {
  const Bin({
    required this.id,
    required this.name,
    required this.address,
    required this.districtId,
    required this.districtName,
    required this.position,
    required this.fillPercent,
    required this.status,
    required this.totalKg,
    required this.kgByMaterial,
    required this.lastCollection,
  });

  final String id;
  final String name;
  final String address;
  final String districtId;
  final String districtName;
  final LatLng position;
  final int fillPercent;
  final BinStatus status;

  /// Total coletado nos últimos 30 dias.
  final double totalKg;
  final Map<WasteMaterial, double> kgByMaterial;
  final DateTime lastCollection;
}
