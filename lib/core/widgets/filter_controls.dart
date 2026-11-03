import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';
import 'package:recicla_radar_sp/state/filters_provider.dart';

/// Escolha do período (7, 30 ou 90 dias).
class PeriodSelector extends StatelessWidget {
  const PeriodSelector({super.key, required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: [
        for (final days in FiltersProvider.periods)
          ButtonSegment(value: days, label: Text('$days dias')),
      ],
      selected: {selected},
      showSelectedIcon: true,
      onSelectionChanged: (values) => onChanged(values.first),
    );
  }
}

/// Filtro de material com opção "Todos".
class MaterialFilter extends StatelessWidget {
  const MaterialFilter({super.key, required this.selected, required this.onChanged});

  final WasteMaterial? selected;
  final ValueChanged<WasteMaterial?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('Todos'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final material in WasteMaterial.values)
          ChoiceChip(
            label: Text(material.label),
            selected: selected == material,
            onSelected: (_) => onChanged(material),
          ),
      ],
    );
  }
}
