import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';

/// Marcador de lixeira: cor + ícone do status e o enchimento em texto.
class BinMarker extends StatelessWidget {
  const BinMarker({super.key, required this.bin, required this.onTap});

  final Bin bin;
  final VoidCallback onTap;

  /// Área do marcador no mapa (a parte que recebe o toque).
  static const double size = 46;

  /// Tamanho do círculo desenhado, menor que a área de toque.
  static const double dotSize = 36;

  @override
  Widget build(BuildContext context) {
    final color = bin.status.color(context);
    final foreground = onColorFor(color);

    return Semantics(
      button: true,
      label: '${bin.name}, ${bin.status.label.toLowerCase()}, '
          '${bin.fillPercent}% cheia. Toque para ver.',
      excludeSemantics: true,
      child: Tooltip(
        message: bin.name,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: foreground, width: 1.5),
              ),
              padding: const EdgeInsets.all(4),
              child: FittedBox(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(bin.status.icon, size: 14, color: foreground),
                    Text(
                      bin.status.isWorking ? '${bin.fillPercent}%' : '--',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Legenda dos status de lixeira (ícone, cor e nome).
class BinLegend extends StatelessWidget {
  const BinLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: 'Legenda: operando, quase cheia, cheia, em manutenção, sem sinal e ponto de descarte.',
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm + 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in BinStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 18, color: status.color(context)),
                      const SizedBox(width: 6),
                      Text(status.label, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: theme.colorScheme.onSurface),
                    const SizedBox(width: 6),
                    Text('Ponto de descarte', style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
