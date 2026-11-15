import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';
import 'package:recicla_radar_sp/features/alerts/alert_decision.dart';

/// Folha de confirmação da decisão. Mostra, em uma frase, o que vai acontecer
/// antes de a pessoa confirmar. Devolve o registro da decisão ou `null` se ela cancelar.
Future<AlertEvent?> showAlertDecisionSheet(
  BuildContext context, {
  required Alert alert,
  required DecisionKind kind,
  required String? by,
}) {
  return showModalBottomSheet<AlertEvent>(
    context: context,
    // Fora da aba atual, para a barra de navegação não cobrir o botão de confirmar.
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _DecisionSheet(alert: alert, kind: kind, by: by),
  );
}

class _DecisionSheet extends StatefulWidget {
  const _DecisionSheet({
    required this.alert,
    required this.kind,
    required this.by,
  });

  final Alert alert;
  final DecisionKind kind;
  final String? by;

  @override
  State<_DecisionSheet> createState() => _DecisionSheetState();
}

class _DecisionSheetState extends State<_DecisionSheet> {
  final _note = TextEditingController();
  late final List<String> _choices = widget.kind.choices(widget.alert.type);
  late String? _choice = _choices.isEmpty ? null : _choices.first;
  DecisionDeadline _deadline = DecisionDeadline.today;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  /// O que vai acontecer, em uma frase, com as escolhas feitas até agora.
  String get _summary {
    final title = widget.alert.title;
    return switch (widget.kind) {
      DecisionKind.investigate =>
        'Você vai assumir este alerta e marcá-lo como "Em análise".',
      DecisionKind.assignTeam =>
        'Você vai alocar "$_choice" para: $title. Prazo: ${_deadline.label.toLowerCase()}.',
      DecisionKind.complete =>
        'Você vai concluir o alerta com o resultado: "$_choice".',
      DecisionKind.discard =>
        'Você vai descartar o alerta. Motivo: "$_choice".',
      DecisionKind.reopen =>
        'Você vai reabrir o alerta, que volta para "Aberto".',
    };
  }

  void _confirm() {
    Navigator.of(context).pop(
      buildDecisionEvent(
        kind: widget.kind,
        choice: _choice,
        note: _note.text,
        deadline: _deadline,
        by: widget.by,
        now: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kind = widget.kind;
    final title = kind.choiceTitle;

    return Padding(
      // Sobe junto com o teclado.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // As escolhas rolam; o resumo e os botões ficam sempre à vista, embaixo.
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                0,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text(
                      kind.label(widget.alert.type),
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(widget.alert.title, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.md),
                  if (title != null) ...[
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    for (final option in _choices)
                      _ChoiceTile(
                        label: option,
                        selected: option == _choice,
                        onTap: () => setState(() => _choice = option),
                      ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (kind == DecisionKind.assignTeam) ...[
                    Text('Prazo', style: theme.textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        for (final deadline in DecisionDeadline.values)
                          ChoiceChip(
                            label: Text(deadline.label),
                            selected: deadline == _deadline,
                            onSelected: (_) =>
                                setState(() => _deadline = deadline),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  if (kind != DecisionKind.reopen &&
                      kind != DecisionKind.investigate) ...[
                    TextField(
                      controller: _note,
                      maxLength: 200,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Observação (opcional)',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // A frase que resume a decisão, para a pessoa conferir antes de confirmar.
                Semantics(
                  liveRegion: true,
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm + 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.person_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            '$_summary Esta decisão é sua e fica registrada no histórico do alerta.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton.icon(
                  onPressed: _confirm,
                  icon: Icon(kind.icon),
                  label: Text(
                    'Confirmar: ${kind.label(widget.alert.type).toLowerCase()}',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma opção da lista (equipe, resultado ou motivo), com alvo de toque de 48 dp.
class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.sm + 4),
              Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
            ],
          ),
        ),
      ),
    );
  }
}
