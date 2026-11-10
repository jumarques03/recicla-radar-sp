import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:recicla_radar_sp/core/utils/formatters.dart';

/// Gráfico de linha simples com rótulos legíveis.
class SimpleLineChart extends StatelessWidget {
  const SimpleLineChart({
    super.key,
    required this.labels,
    required this.values,
    this.maxY,
    this.formatY,
    this.formatTooltip,
  });

  final List<String> labels;
  final List<double> values;
  final double? maxY;
  final String Function(double value)? formatY;

  /// Texto do valor ao tocar num ponto. Sem isso, usa duas casas decimais.
  final String Function(double value)? formatTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;
    final labelStyle = theme.textTheme.bodySmall;
    final labelEvery = labels.length > 8 ? 2 : 1;
    String format(double v) => formatY?.call(v) ?? v.round().toString();
    String tooltip(double v) => formatTooltip?.call(v) ?? Formatters.decimal(v);

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
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
                if (value == meta.max || value == meta.min && value != 0) {
                  return const SizedBox.shrink();
                }
                return Text(format(value), style: labelStyle, softWrap: false);
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= labels.length || index % labelEvery != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(labels[index], style: labelStyle),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i])],
            isCurved: true,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 4,
            dotData: const FlDotData(),
            belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.12)),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final spot in spots)
                LineTooltipItem(
                  '${labels[spot.x.toInt()]}\n${tooltip(spot.y)}',
                  TextStyle(
                    color: theme.colorScheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
