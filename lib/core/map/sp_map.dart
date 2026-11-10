import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Configuração comum aos mapas do app: sempre focados no município de São Paulo.
abstract final class SpMap {
  /// Caixa que cobre o município (Marsilac ao sul, Perus ao norte).
  static final LatLngBounds bounds = LatLngBounds(
    const LatLng(-24.02, -46.84),
    const LatLng(-23.34, -46.35),
  );

  static const LatLng center = LatLng(-23.68, -46.62);

  /// Limite até onde a pessoa pode levar o centro do mapa ao arrastar.
  static final LatLngBounds panLimit = LatLngBounds(
    const LatLng(-24.05, -46.90),
    const LatLng(-23.30, -46.30),
  );

  static const String tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String userAgent = 'br.com.fiap.recicla_radar_sp';

  static MapOptions options({double maxZoom = 17}) {
    return MapOptions(
      // Posição já dentro de São Paulo: vale até o enquadramento abaixo ser aplicado.
      // Sem ela o mapa começa em Kiev, fora do limite de arrasto, e uma
      // reconstrução da tela nesse instante quebra a câmera.
      initialCenter: center,
      initialZoom: 9.6,
      initialCameraFit: CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(8)),
      // Só o centro precisa ficar na área; assim funciona em qualquer tamanho de tela.
      cameraConstraint: CameraConstraint.containCenter(bounds: panLimit),
      minZoom: 9,
      maxZoom: maxZoom,
    );
  }

  static TileLayer tileLayer() => TileLayer(urlTemplate: tileUrl, userAgentPackageName: userAgent);
}
