import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class AquaWalletPriceChart extends StatelessWidget {
  const AquaWalletPriceChart({
    super.key,
    required this.data,
    required this.isNegative,
    this.colors,
  });

  final List<ChartDataItem> data;
  final bool isNegative;
  final AquaColors? colors;

  @override
  Widget build(BuildContext context) {
    final lineColor = isNegative ? colors?.accentDanger : colors?.accentSuccess;
    final gradientColor = isNegative
        ? colors?.accentDangerTransparent
        : colors?.accentSuccessTransparent;

    return Container(
      width: 120,
      height: 75,
      decoration: BoxDecoration(
        color: isNegative
            ? colors?.accentDangerTransparent.withAlpha(55)
            : colors?.accentSuccessTransparent.withAlpha(55),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: 7,
          minY: data.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 2,
          maxY: data.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 2,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: data.map((e) => FlSpot(e.x, e.y)).toList(),
              isCurved: true,
              curveSmoothness: 0.35,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    gradientColor?.withAlpha(255) ?? Colors.transparent,
                    gradientColor?.withAlpha(18) ?? Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
