import 'package:ui_components/ui_components.dart';

class BtcPriceHistoryUiModel {
  final bool isNegative;
  final String? trendAmount;
  final String? trendPercent;
  final List<ChartDataItem>? priceChartData;
  final bool isCached;

  BtcPriceHistoryUiModel({
    required this.isNegative,
    required this.trendAmount,
    required this.trendPercent,
    required this.priceChartData,
    required this.isCached,
  });
}
