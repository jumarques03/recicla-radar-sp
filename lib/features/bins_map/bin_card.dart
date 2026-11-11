import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/theme/status_colors.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/core/widgets/status_chip.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';

/// Barra de enchimento com a porcentagem escrita ao lado.
class FillBar extends StatelessWidget {
  const FillBar({super.key, required this.percent, required this.color, this.height = 12});

  final int percent;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(height),
            // Anima até o valor, e de novo se o enchimento mudar.
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: percent / 100),
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: height,
                color: color,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm + 4),
        Text('$percent%', style: theme.textTheme.titleMedium),
      ],
    );
  }
}

class BinCard extends StatelessWidget {
  const BinCard({super.key, required this.bin, required this.onTap, this.activeAlerts = 0});

  final Bin bin;
  final VoidCallback onTap;

  /// Alertas ativos desta lixeira.
  final int activeAlerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: onTap,
      semanticLabel: '${bin.name}, ${bin.districtName}. ${bin.status.label}, '
          '${bin.fillPercent}% cheia.${activeAlerts > 0 ? ' $activeAlerts alertas ativos.' : ''} Última coleta ${Formatters.timeAgo(bin.lastCollection)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(bin.name, style: theme.textTheme.titleMedium)),
              const Icon(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            bin.districtName,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          FillBar(percent: bin.fillPercent, color: bin.status.color(context)),
          const SizedBox(height: AppSpacing.sm + 4),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              BinStatusChip(bin.status),
              if (activeAlerts > 0)
                StatusChip(
                  icon: Icons.notifications_active_outlined,
                  label: activeAlerts == 1 ? '1 alerta' : '$activeAlerts alertas',
                  color: context.statusColors.warning,
                ),
              Text(
                'Coleta ${Formatters.timeAgo(bin.lastCollection)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
