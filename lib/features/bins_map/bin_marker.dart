import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/data/models/district.dart';

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

/// Legenda do mapa de lixeiras. Começa recolhida para não cobrir o mapa;
/// ao tocar, mostra os status, o ponto de descarte e a cor dos distritos.
class BinLegend extends StatefulWidget {
  const BinLegend({super.key});

  @override
  State<BinLegend> createState() => _BinLegendState();
}

class _BinLegendState extends State<BinLegend> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            expanded: _expanded,
            label: _expanded ? 'Legenda do mapa. Toque para fechar.' : 'Legenda do mapa. Toque para abrir.',
            excludeSemantics: true,
            child: InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: AppSpacing.minTouch),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.info_outline, size: 20),
                      const SizedBox(width: AppSpacing.sm),
                      Text('Legenda', style: theme.textTheme.labelLarge),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm + 4,
                0,
                AppSpacing.sm + 4,
                AppSpacing.sm + 4,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final status in BinStatus.values)
                    _LegendRow(
                      leading: Icon(status.icon, size: 18, color: status.color(context)),
                      label: status.label,
                    ),
                  _LegendRow(
                    leading: Icon(Icons.delete_sweep_outlined, size: 18, color: theme.colorScheme.onSurface),
                    label: 'Ponto de descarte',
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text('Cor do distrito (demanda)', style: theme.textTheme.labelMedium),
                  for (final level in DemandLevel.values)
                    _LegendRow(
                      leading: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: level.color(context).withValues(alpha: 0.45),
                          border: Border.all(color: level.color(context)),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      label: level.label,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.leading, required this.label});

  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
