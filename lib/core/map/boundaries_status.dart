import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/state/boundaries_provider.dart';
import 'package:recicla_radar_sp/state/loadable_notifier.dart';

/// Aviso no canto do mapa enquanto os limites carregam ou se deram erro.
/// Quando estão prontos, não mostra nada.
class BoundariesStatus extends StatelessWidget {
  const BoundariesStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BoundariesProvider>();
    final theme = Theme.of(context);

    final Widget? content = switch (provider.status) {
      LoadStatus.idle || LoadStatus.loading => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text('Carregando limites dos distritos...', style: theme.textTheme.bodySmall),
            ),
          ],
        ),
      LoadStatus.error => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_outlined, size: 20, color: theme.colorScheme.error),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text('Limites indisponíveis', style: theme.textTheme.bodySmall),
            ),
            TextButton(
              onPressed: provider.load,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      LoadStatus.ready => null,
    };
    if (content == null) return const SizedBox.shrink();

    return Semantics(
      liveRegion: true,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 4, vertical: AppSpacing.xs),
          child: content,
        ),
      ),
    );
  }
}
