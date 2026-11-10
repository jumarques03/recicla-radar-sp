import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/district.dart';

/// Ponto de um distrito no mapa. Com o mapa afastado é só uma bolinha colorida;
/// ao aproximar, mostra o ícone do nível e o número do índice.
class DemandBubble extends StatelessWidget {
  const DemandBubble({
    super.key,
    required this.district,
    required this.onTap,
    required this.compact,
  });

  final District district;
  final VoidCallback onTap;

  /// `true` para a bolinha pequena, sem texto.
  final bool compact;

  /// Área do marcador no mapa (a parte que recebe o toque).
  static double markerSize({required bool compact}) => compact ? 24 : 40;

  /// Tamanho do círculo desenhado.
  static double dotSize({required bool compact}) => compact ? 16 : 34;

  @override
  Widget build(BuildContext context) {
    final color = district.level.color(context);
    final foreground = onColorFor(color);
    final dot = dotSize(compact: compact);

    return Semantics(
      button: true,
      label: '${district.name}, demanda ${district.level.label.toLowerCase()}, '
          'índice ${district.demandIndex}. Toque para ver detalhes.',
      excludeSemantics: true,
      child: Tooltip(
        message: district.name,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Container(
              width: dot,
              height: dot,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                border: Border.all(color: foreground, width: compact ? 1.5 : 2),
              ),
              child: compact
                  ? null
                  : FittedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(district.level.icon, color: foreground, size: 14),
                            Text(
                              '${district.demandIndex}',
                              style: TextStyle(
                                color: foreground,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ],
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
