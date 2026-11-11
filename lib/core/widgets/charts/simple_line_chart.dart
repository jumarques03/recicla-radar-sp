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
    this.autoScale = false,
    this.formatY,
    this.formatTooltip,
  });

  final List<String> labels;
  final List<double> values;
  final double? maxY;

  /// Ajusta a escala vertical aos valores (em vez de começar do zero), para a variação
  /// aparecer. Os três números do eixo ficam em múltiplos de 10.
  final bool autoScale;

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

    // Escala: do zero ao máximo, ou só a faixa dos valores quando [autoScale].
    var minAxis = 0.0;
    var maxAxis = maxY;
    if (autoScale && values.isNotEmpty) {
      final low = values.reduce((a, b) => a < b ? a : b);
      final high = values.reduce((a, b) => a > b ? a : b);
      minAxis = (((low - 4) / 10).floor() * 10.0).clamp(0, 1000);
      var top = (((high + 4) / 10).ceil() * 10.0);
      if (maxY != null && top > maxY!) top = maxY!;
      // A altura do eixo vira múltiplo de 20, para o rótulo do meio cair num número redondo.
      var span = top - minAxis;
      if (span < 20) span = 20;
      span = (span / 20).ceil() * 20.0;
      maxAxis = minAxis + span;
      if (maxY != null && maxAxis > maxY!) {
        maxAxis = maxY!;
        minAxis = (maxAxis - span).clamp(0, maxAxis);
      }
    }
    final leftInterval = autoScale && maxAxis != null
        ? (maxAxis - minAxis) / 2
        : null;

    final spots = [
      for (var i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
    ];
    final bar = LineChartBarData(
      spots: spots,
      isCurved: true,
      preventCurveOverShooting: true,
      color: color,
      barWidth: 4,
      dotData: const FlDotData(),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.12),
      ),
    );

    return LineChart(
      LineChartData(
        minY: minAxis,
        maxY: maxAxis,

        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: leftInterval,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: theme.colorScheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: autoScale ? 40 : 60,
              interval: leftInterval,
              getTitlesWidget: (value, meta) {
                if (!autoScale &&
                    (value == meta.max || value == meta.min && value != 0)) {
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
                if (index < 0 ||
                    index >= labels.length ||
                    index % labelEvery != 0) {
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
        lineBarsData: [bar],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
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
