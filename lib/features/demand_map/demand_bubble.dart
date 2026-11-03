import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/data/models/district.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';

/// Círculo de um distrito no mapa: cor pelo nível, ícone e número do índice.
class DemandBubble extends StatelessWidget {
  const DemandBubble({super.key, required this.district, required this.onTap});

  final District district;
  final VoidCallback onTap;

  /// Cresce com a demanda, mas nunca fica menor que um alvo de toque (48).
  static double sizeFor(District district) => 52 + district.demandIndex / 100 * 28;

  @override
  Widget build(BuildContext context) {
    final color = district.level.color(context);
    final foreground = onColorFor(color);

    return Semantics(
      button: true,
      label: '${district.name}, demanda ${district.level.label.toLowerCase()}, '
          'índice ${district.demandIndex}. Toque para ver detalhes.',
      excludeSemantics: true,
      child: Tooltip(
        message: district.name,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.92),
              border: Border.all(color: foreground, width: 2),
            ),
            padding: const EdgeInsets.all(6),
            child: FittedBox(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(district.level.icon, color: foreground, size: 18),
                  Text(
                    '${district.demandIndex}',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
