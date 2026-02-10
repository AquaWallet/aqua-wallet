import 'dart:convert';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/ui_components.dart';

/// Provider to fetch the bitcoin price history UI model using Jan3ApiService.
final bitcoinPriceHistoryProvider = StreamNotifierProvider<
    BitcoinPriceHistoryNotifier,
    BtcPriceHistoryUiModel?>(BitcoinPriceHistoryNotifier.new);

class BitcoinPriceHistoryNotifier
    extends StreamNotifier<BtcPriceHistoryUiModel?> {
  @override
  Stream<BtcPriceHistoryUiModel?> build() async* {
    final cache = ref.read(keyValueCacheServiceProvider);
    final cachedBtcPriceHistory = cache.get(CacheKey.btcPriceHistory);

    if (cachedBtcPriceHistory != null) {
      final json = jsonDecode(cachedBtcPriceHistory.value);
      // Prepare chart data
      final items =
          json.map((s) => double.parse(s.trim())).cast<double>().toList();
      final chartData = List.generate(
        items.length,
        (i) => ChartDataItem(i.toDouble(), items[i]),
      );

      yield BtcPriceHistoryUiModel(
        isNegative: false,
        trendAmount: null,
        trendPercent: null,
        isCached: true,
        priceChartData: chartData,
      );
    } else {
      yield BtcPriceHistoryUiModel(
        isNegative: false,
        trendAmount: null,
        trendPercent: null,
        isCached: true,
        priceChartData: null,
      );
    }

    final api = await ref.read(jan3ApiServiceProvider.future);
    final currency = ref.watch(exchangeRatesProvider).currentCurrency.currency;
    final lastDayResponse = await api.getLastDayPrices(currency: currency.name);
    final prices = lastDayResponse.isSuccessful ? lastDayResponse.body : null;
    final formatter = ref.read(formatProvider);
    if (prices == null || prices.isEmpty) {
      return;
    }

    // Sort by timestamp ascending
    prices.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Sample every 30 minutes for the chart
    final sampled = prices.fold<List<DailyPriceResponse>>(
      [],
      (acc, price) => acc.isEmpty ||
              price.timestamp.difference(acc.last.timestamp).inMinutes >= 30
          ? [...acc, price]
          : acc,
    );

    // Always include the last point if not already included
    final sampledWithLast =
        sampled.isEmpty || sampled.last.timestamp != prices.last.timestamp
            ? [...sampled, prices.last]
            : sampled;

    if (sampledWithLast.isNotEmpty) {
      final rawValues = sampledWithLast.map((p) => p.price).toList();
      cache.save(
        CacheKey.btcPriceHistory,
        jsonEncode(rawValues),
      );
    }

    // Find latest and 24h-ago price
    final latest = prices.last;
    final target24hAgo = latest.timestamp.subtract(const Duration(hours: 24));
    DailyPriceResponse? price24hAgo = prices.firstWhere(
      (p) =>
          p.timestamp.isAfter(target24hAgo) ||
          p.timestamp.isAtSameMomentAs(target24hAgo),
      orElse: () => prices.first,
    );
    // If the found price is not close enough (e.g. >1h diff), fallback to daily price API
    if ((latest.timestamp.difference(price24hAgo.timestamp).inHours < 23) &&
        (price24hAgo.timestamp.difference(target24hAgo).inMinutes.abs() > 60)) {
      final dailyPriceRes = await api.getDailyPrice(currency: currency.name);
      if (dailyPriceRes.isSuccessful && dailyPriceRes.body != null) {
        price24hAgo = dailyPriceRes.body!;
      }
    }

    final latestPrice = double.tryParse(latest.price) ?? 0;
    final price24h = double.tryParse(price24hAgo.price) ?? 0;

    // Convert BTC price difference to fiat
    final diffFiat = latestPrice - price24h;
    final isNegative = diffFiat < 0;
    final percent = price24h == 0 ? 0 : (diffFiat / price24h) * 100;

    final percentFormat = NumberFormat('#,##0.00%', 'en');

    String? trendAmount;
    if (price24h != 0) {
      String formattedFiat = formatter.formatFiatAmount(
        amount: Decimal.parse(diffFiat.abs().toString()),
        withSymbol: false,
      );

      if (isNegative) {
        trendAmount = "-$formattedFiat";
      } else {
        trendAmount = "+$formattedFiat";
      }
    }

    final trendPercent =
        price24h == 0 ? null : percentFormat.format(percent.abs() / 100);

    // Prepare chart data
    final chartData = sampledWithLast
        .map((p) => p.price)
        .whereNotNull()
        .mapIndexed((i, p) => ChartDataItem(i.toDouble(), double.parse(p)))
        .toList();

    yield BtcPriceHistoryUiModel(
      isNegative: isNegative,
      trendAmount: trendAmount,
      trendPercent: trendPercent,
      priceChartData: chartData,
      isCached: false,
    );
  }
}
