import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/district.dart';

/// Lista dos distritos, do que mais descarta para o que menos descarta.
/// É a alternativa ao mapa e mostra a demanda também em texto.
class DemandDistrictList extends StatelessWidget {
  const DemandDistrictList({
    super.key,
    required this.districts,
    required this.rankOf,
    required this.onTap,
  });

  final List<District> districts;
  final int Function(District district) rankOf;
  final ValueChanged<District> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = [...districts]..sort((a, b) => b.demandIndex.compareTo(a.demandIndex));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      itemCount: sorted.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm + 4),
      itemBuilder: (context, index) {
        final district = sorted[index];
        final rank = rankOf(district);
        return AppCard(
          onTap: () => onTap(district),
          semanticLabel: '$rankº lugar, ${district.name}. Demanda '
              '${district.level.label.toLowerCase()}, índice ${district.demandIndex}.',
          child: Row(
            children: [
              SizedBox(
                width: 44,
                child: Text('$rankº', style: theme.textTheme.titleMedium),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(district.name, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        DemandLevelChip(district.level),
                        Text('${district.binCount} lixeiras', style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('${district.demandIndex}', style: theme.textTheme.headlineSmall),
            ],
          ),
        );
      },
    );
  }
}
