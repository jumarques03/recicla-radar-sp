import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/theme/app_colors.dart';
import 'package:recicla_radar_sp/core/theme/app_spacing.dart';
import 'package:recicla_radar_sp/core/utils/formatters.dart';
import 'package:recicla_radar_sp/data/models/waste_material.dart';

/// Texto que resume a divisão por material, para leitores de tela.
String describeMaterials(Map<WasteMaterial, double> kgByMaterial) {
  return WasteMaterial.values
      .map((m) => '${m.label} ${Formatters.kg(kgByMaterial[m] ?? 0)}')
      .join(', ');
}

/// Barras de kg por material.
class MaterialBarChart extends StatelessWidget {
  const MaterialBarChart({super.key, required this.kgByMaterial});

  final Map<WasteMaterial, double> kgByMaterial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final labelStyle = theme.textTheme.bodySmall;
    final materials = WasteMaterial.values;
    final maxValue = kgByMaterial.values.fold(0.0, (a, b) => a > b ? a : b);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxValue == 0 ? 1 : maxValue * 1.15,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Text(Formatters.compactKg(value), style: labelStyle, softWrap: false);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) => Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(materials[value.toInt()].label, style: labelStyle),
              ),
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
              '${materials[group.x].label}\n${Formatters.kg(rod.toY)}',
              TextStyle(
                color: theme.colorScheme.onInverseSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < materials.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: kgByMaterial[materials[i]] ?? 0,
                  width: 28,
                  color: AppColors.material(materials[i], brightness),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Pizza com a participação de cada material.
class MaterialPieChart extends StatelessWidget {
  const MaterialPieChart({super.key, required this.kgByMaterial});

  final Map<WasteMaterial, double> kgByMaterial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = kgByMaterial.values.fold(0.0, (a, b) => a + b);

    return PieChart(
      PieChartData(
        sectionsSpace: 3,
        centerSpaceRadius: 36,
        sections: [
          for (final material in WasteMaterial.values)
            if ((kgByMaterial[material] ?? 0) > 0)
              () {
                final color = AppColors.material(material, theme.brightness);
                final value = kgByMaterial[material]!;
                return PieChartSectionData(
                  value: value,
                  color: color,
                  radius: 64,
                  title: Formatters.percentDecimal(value / total * 100),
                  titleStyle: theme.textTheme.labelMedium?.copyWith(color: onColorFor(color)),
                );
              }(),
        ],
      ),
    );
  }
}

/// Legenda com cor, nome e valor de cada material.
class MaterialLegend extends StatelessWidget {
  const MaterialLegend({super.key, required this.kgByMaterial});

  final Map<WasteMaterial, double> kgByMaterial;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        for (final material in WasteMaterial.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.material(material, theme.brightness),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  '${material.label}: ${Formatters.kg(kgByMaterial[material] ?? 0)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
