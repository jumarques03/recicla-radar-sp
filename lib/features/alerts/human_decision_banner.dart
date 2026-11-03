import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';

/// Faixa fixa lembrando que o sistema sugere e a pessoa decide.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      container: true,
      child: Container(
        width: double.infinity,
        color: scheme.secondaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 4),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.sm + 4),
            Expanded(
              child: Text(
                'Os alertas apoiam, mas não substituem, a decisão humana.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSecondaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
