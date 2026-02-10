import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

const _kSkeletonPrice = 100000.0;
const _kSkeletonChartItemsCount = 31;
const _kPaddingRatio = 0.995;

class AquaBtcPriceChart extends StatelessWidget {
  const AquaBtcPriceChart({
    super.key,
    required this.data,
    required this.isSkeleton,
  });

  final List<ChartDataItem>? data;
  final bool isSkeleton;

  @override
  Widget build(BuildContext context) {
    final isNoHistory = data == null || data!.isEmpty;
    final items = data ??
        List.generate(
          _kSkeletonChartItemsCount,
          (index) => ChartDataItem(index.toDouble(), _kSkeletonPrice),
        );
    final maxYVal = items.map((e) => e.y).max;

    return Container(
      height: 68,
      padding: const EdgeInsets.only(right: 32),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          // Finds the min Y value in the data & adds padding at the bottom
          minY: isNoHistory ? 0 : items.map((e) => e.y).min * _kPaddingRatio,
          maxY: isNoHistory ? _kSkeletonPrice * 2 : maxYVal + (maxYVal * 0.01),
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: items.map((e) => FlSpot(e.x, e.y)).toList(),
              isCurved: true,
              curveSmoothness: 0.1,
              color: AquaPrimitiveColors.aquaBlue300,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                checkToShowDot: (spot, _) => spot.x == items.length - 1,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 4,
                  color: isSkeleton
                      ? Theme.of(context).brightness == Brightness.light
                          ? Colors.grey.shade200
                          : Colors.grey.shade800
                      : AquaPrimitiveColors.aquaBlue300,
                  strokeColor: isSkeleton
                      ? Colors.transparent
                      : AquaPrimitiveColors.aquaBlue16,
                  strokeWidth: 6,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x6D00C7F9),
                    Color(0x1000C7F9),
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
