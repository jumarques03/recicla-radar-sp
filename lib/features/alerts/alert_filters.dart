import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/data/models/alert.dart';

/// Filtros escolhidos na lista de alertas. `null` significa "todos".
class AlertFilters {
  const AlertFilters({this.type, this.severity, this.status, this.onlyNew = false});

  final AlertType? type;
  final AlertSeverity? severity;
  final AlertStatus? status;

  /// Mostra só os alertas que a pessoa ainda não viu.
  final bool onlyNew;

  int get activeCount =>
      [type, severity, status].where((f) => f != null).length + (onlyNew ? 1 : 0);

  bool matches(Alert alert, {required bool Function(String id) isSeen}) =>
      (!onlyNew || !isSeen(alert.id)) &&
      (type == null || alert.type == type) &&
      (severity == null || alert.severity == severity) &&
      (status == null || alert.status == status);

  AlertFilters copyWith({
    AlertType? type,
    AlertSeverity? severity,
    AlertStatus? status,
    bool clearType = false,
    bool clearSeverity = false,
    bool clearStatus = false,
    bool? onlyNew,
  }) {
    return AlertFilters(
      type: clearType ? null : (type ?? this.type),
      severity: clearSeverity ? null : (severity ?? this.severity),
      status: clearStatus ? null : (status ?? this.status),
      onlyNew: onlyNew ?? this.onlyNew,
    );
  }
}

/// Painel recolhível com os filtros por tipo, gravidade e situação.
class AlertFilterPanel extends StatelessWidget {
  const AlertFilterPanel({super.key, required this.filters, required this.onChanged});

  final AlertFilters filters;
  final ValueChanged<AlertFilters> onChanged;

  @override
  Widget build(BuildContext context) {
    final count = filters.activeCount;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: const Icon(Icons.filter_list),
        title: Text(count == 0 ? 'Filtros' : 'Filtros ($count ativos)'),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mostrar só os não lidos'),
            subtitle: const Text('Alertas que você ainda não leu'),
            value: filters.onlyNew,
            onChanged: (value) => onChanged(filters.copyWith(onlyNew: value)),
          ),
          _FilterGroup<AlertType>(
            title: 'Tipo',
            values: AlertType.values,
            selected: filters.type,
            labelOf: (v) => v.label,
            onChanged: (v) => onChanged(
              v == null ? filters.copyWith(clearType: true) : filters.copyWith(type: v),
            ),
          ),
          _FilterGroup<AlertSeverity>(
            title: 'Gravidade',
            values: AlertSeverity.values,
            selected: filters.severity,
            labelOf: (v) => v.label,
            onChanged: (v) => onChanged(
              v == null ? filters.copyWith(clearSeverity: true) : filters.copyWith(severity: v),
            ),
          ),
          _FilterGroup<AlertStatus>(
            title: 'Situação',
            values: AlertStatus.values,
            selected: filters.status,
            labelOf: (v) => v.label,
            onChanged: (v) => onChanged(
              v == null ? filters.copyWith(clearStatus: true) : filters.copyWith(status: v),
            ),
          ),
          if (count > 0)
            TextButton.icon(
              onPressed: () => onChanged(const AlertFilters()),
              icon: const Icon(Icons.clear),
              label: const Text('Limpar filtros'),
            ),
        ],
      ),
    );
  }
}

class _FilterGroup<T> extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T? selected;
  final String Function(T value) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: selected == null,
                onSelected: (_) => onChanged(null),
              ),
              for (final value in values)
                ChoiceChip(
                  label: Text(labelOf(value)),
                  selected: selected == value,
                  onSelected: (_) => onChanged(value),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
