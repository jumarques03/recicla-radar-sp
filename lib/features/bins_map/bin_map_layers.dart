import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/disposal_point.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_marker.dart';

/// Camada de lixeiras. Lixeiras que ficariam uma em cima da outra viram um
/// círculo com a quantidade; ao tocar, o mapa aproxima.
class BinClusterLayer extends StatelessWidget {
  const BinClusterLayer({super.key, required this.bins, required this.onBinTap});

  final List<Bin> bins;
  final ValueChanged<Bin> onBinTap;

  /// Tamanho, em pixels da tela, da célula usada para juntar lixeiras.
  static const double _cellSize = 72;

  /// Com o mapa mais aproximado que isso, cada lixeira aparece sozinha.
  static const double _singleZoom = 16.5;
  static const double _maxZoom = 17;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final controller = MapController.of(context);
    final groups = <(int, int), List<Bin>>{};

    for (var i = 0; i < bins.length; i++) {
      final bin = bins[i];
      final pixel = camera.projectAtZoom(bin.position);
      final cell = camera.zoom >= _singleZoom
          ? (i, -1)
          : ((pixel.dx / _cellSize).floor(), (pixel.dy / _cellSize).floor());
      groups.putIfAbsent(cell, () => []).add(bin);
    }

    return MarkerLayer(
      markers: [
        for (final group in groups.values)
          if (group.length == 1)
            Marker(
              point: group.first.position,
              width: BinMarker.size,
              height: BinMarker.size,
              child: BinMarker(bin: group.first, onTap: () => onBinTap(group.first)),
            )
          else
            _clusterMarker(group, camera, controller),
      ],
    );
  }

  Marker _clusterMarker(List<Bin> group, MapCamera camera, MapController controller) {
    final center = LatLng(
      group.map((bin) => bin.position.latitude).reduce((a, b) => a + b) / group.length,
      group.map((bin) => bin.position.longitude).reduce((a, b) => a + b) / group.length,
    );
    return Marker(
      point: center,
      width: BinMarker.size,
      height: BinMarker.size,
      child: _ClusterBubble(
        count: group.length,
        onTap: () => controller.move(center, min(camera.zoom + 2, _maxZoom)),
      ),
    );
  }
}

class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: '$count lixeiras agrupadas. Toque para aproximar o mapa.',
      excludeSemantics: true,
      child: Tooltip(
        message: '$count lixeiras',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scheme.primary,
              border: Border.all(color: scheme.onPrimary, width: 2),
            ),
            alignment: Alignment.center,
            child: FittedBox(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Camada com os pontos de descarte. Só aparece com o mapa aproximado, para
/// não poluir a visão da cidade inteira.
class DisposalPointLayer extends StatelessWidget {
  const DisposalPointLayer({super.key, required this.points});

  final List<DisposalPoint> points;

  static const double minZoom = 14.5;
  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    if (MapCamera.of(context).zoom < minZoom) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return MarkerLayer(
      markers: [
        for (final point in points)
          Marker(
            point: point.position,
            width: _size,
            height: _size,
            child: Semantics(
              label: 'Ponto de descarte: ${point.name}',
              child: Tooltip(
                message: point.name,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Cor neutra, para não parecer um status de lixeira.
                    color: scheme.surface,
                    border: Border.all(color: scheme.onSurface, width: 1.5),
                  ),
                  child: Icon(
                    Icons.delete_sweep_outlined,
                    size: 18,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
