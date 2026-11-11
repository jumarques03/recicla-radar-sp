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
    // Chips do mesmo tamanho, em grade: 3 por linha no celular e todos numa linha
    // quando há espaço. Assim nada fica cortado nem desalinhado.
    const gap = AppSpacing.sm;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 520 ? 5 : 3;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;

        Widget chip(String label, bool isSelected, VoidCallback onTap) => SizedBox(
          width: width,
          child: ChoiceChip(
            label: SizedBox(width: double.infinity, child: Text(label, textAlign: TextAlign.center)),
            selected: isSelected,
            onSelected: (_) => onTap(),
            visualDensity: VisualDensity.compact,
            labelPadding: const EdgeInsets.symmetric(horizontal: 2),
          ),
        );

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            chip('Todos', selected == null, () => onChanged(null)),
            for (final material in WasteMaterial.values)
              chip(material.label, selected == material, () => onChanged(material)),
          ],
        );
      },
    );
  }
}
