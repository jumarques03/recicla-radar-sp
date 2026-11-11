import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/core/widgets/app_card.dart';
import 'package:recicla_radar_sp/core/widgets/status_badges.dart';
import 'package:recicla_radar_sp/core/widgets/status_chip.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    this.isNew = false,
    this.onToggleRead,
  });

  final Alert alert;

  /// Ainda não foi lido pela pessoa.
  final bool isNew;
  final VoidCallback onTap;

  /// Marca este alerta como lido ou como não lido. Sem ele, o botão não aparece.
  final VoidCallback? onToggleRead;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final toggle = onToggleRead;
    final card = AppCard(
      onTap: onTap,
      semanticLabel:
          '${isNew ? 'Não lido. ' : ''}${alert.title}. ${alert.location}. '
          'Gravidade ${alert.severity.label.toLowerCase()}. '
          'Confiança ${alert.confidence.label}. ${alert.status.label}. '
          '${Formatters.timeAgo(alert.createdAt)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            // Deixa espaço para o botão de lido/não lido, no canto do card.
            padding: EdgeInsetsDirectional.only(end: toggle == null ? 0 : 40),
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                if (isNew)
                  StatusChip(
                    icon: Icons.fiber_manual_record,
                    label: 'Não lido',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                SeverityChip(alert.severity),
                ConfidenceChip(alert.confidence),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Text(alert.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.place_outlined,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(alert.location, style: theme.textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 4),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AlertStatusChip(alert.status),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    Formatters.timeAgo(alert.createdAt),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (toggle == null) return card;
    return Stack(
      children: [
        card,
        PositionedDirectional(
          top: 2,
          end: 2,
          // Fica fora do card para leitores de tela encontrarem o botão à parte.
          child: IconButton(
            tooltip: isNew ? 'Marcar como lido' : 'Marcar como não lido',
            icon: Icon(
              isNew
                  ? Icons.mark_email_read_outlined
                  : Icons.mark_email_unread_outlined,
            ),
            onPressed: toggle,
          ),
        ),
      ],
    );
  }
}
