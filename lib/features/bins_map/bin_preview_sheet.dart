import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:recicla_radar_sp/core/router/app_routes.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/data/models/bin.dart';
import 'package:recicla_radar_sp/features/bins_map/bin_card.dart';

/// Resumo da lixeira que aparece ao tocar num marcador do mapa.
class BinPreviewSheet extends StatelessWidget {
  const BinPreviewSheet({super.key, required this.bin, required this.onOpenDetails});

  final Bin bin;
  final VoidCallback onOpenDetails;

  static void show(BuildContext context, Bin bin) {
    final router = GoRouter.of(context);
    showModalBottomSheet<void>(
      context: context,
      // Por cima do app todo; senão a barra de navegação esconde a parte de baixo do painel.
      useRootNavigator: true,
      builder: (sheetContext) => BinPreviewSheet(
        bin: bin,
        onOpenDetails: () {
          Navigator.of(sheetContext).pop();
          router.pushNamed(AppRoutes.bin, pathParameters: {'id': bin.id});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(header: true, child: Text(bin.name, style: theme.textTheme.titleLarge)),
            const SizedBox(height: AppSpacing.xs),
            Text(bin.address, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            FillBar(percent: bin.fillPercent, color: bin.status.color(context)),
            const SizedBox(height: AppSpacing.sm + 4),
            Align(alignment: Alignment.centerLeft, child: BinStatusChip(bin.status)),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onOpenDetails,
              child: const Text('Ver detalhes'),
            ),
          ],
        ),
      ),
    );
  }
}
