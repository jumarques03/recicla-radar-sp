import 'package:latlong2/latlong.dart';

/// Lugar onde as pessoas mais descartam lixo (terminal, feira, praça...).
/// As lixeiras são instaladas perto desses pontos. Dados simulados.
class DisposalPoint {
  const DisposalPoint({
    required this.id,
    required this.name,
    required this.districtId,
    required this.position,
    required this.intensity,
  });

  final String id;
  final String name;
  final String districtId;
  final LatLng position;

  /// De 1 a 10: quanto lixo se descarta ali. Define a demanda do distrito e
  /// quanto cada lixeira vizinha coleta.
  final int intensity;
}
