import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveSwapInformation extends HookConsumerWidget {
  const ReceiveSwapInformation({
    super.key,
    required this.order,
    required this.swapPair,
    required this.deliverAssetNetwork,
  });

  final SwapOrder? order;
  final SwapPair swapPair;
  final String deliverAssetNetwork;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkFee = order == null
        ? '---'
        : order!.hasNetworkFee
            ? '~\$${order!.displayNetworkFeeForUSDt}'
            : context.loc.noFee;
    final serviceFee = order?.serviceFee.value == Decimal.zero
        ? context.loc.noFee
        : order?.serviceFee.displayFee() ?? '---';

    final swapArgs = useMemoized(
      () => SwapArgs(pair: swapPair),
      [swapPair],
    );
    final rate = ref.watch(swapOrderProvider(swapArgs)).valueOrNull?.rate;

    useEffect(() {
      ref.read(swapOrderProvider(swapArgs).notifier).getRate();
      return null;
    }, [swapPair]);

    final needsAmount =
        ref.read(swapOrderProvider(swapArgs).notifier).needsAmountOnReceive;

    final formatter = ref.read(formatProvider);
    final formatAmount = useCallback((Decimal? amount) {
      if (amount == null) return '--';
      return formatter.formatFiatAmount(
        amount: amount,
        withSymbol: false,
      );
    }, [swapPair]);

    final minAmount = rate?.min;
    final maxAmount = rate?.max;

    if (order == null) {
      return const SizedBox.shrink();
    }

    return AquaCard.glass(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (needsAmount) ...[
            //ANCHOR - Range Min/Max
            AquaListItem(
              title: context.loc.amount,
              subtitleTrailing: '${formatAmount(order?.depositAmount)} USDt',
            ),
          ] else ...[
            //ANCHOR - Range Min/Max
            AquaListItem(
              title: context.loc.range,
              subtitleTrailing:
                  '${formatAmount(minAmount)} - ${formatAmount(maxAmount)} USDt',
            ),
          ],

          const SizedBox(height: 1),
          //ANCHOR - Swap Service Fee
          AquaListItem(
            title: context.loc.receiveAssetScreenSwapServiceFee,
            subtitleTrailing: serviceFee,
          ),
          const SizedBox(height: 1),
          //ANCHOR - Provider Processing Fee
          AquaListItem(
            title: context.loc
                .providerProcessingFee(_getProviderTitle(order, swapPair)),
            subtitleTrailing: networkFee,
          ),
          const SizedBox(height: 1),
          //ANCHOR - Swap ID with copy button
          if ((order?.id ?? '').isNotEmpty) ...[
            AquaListItem(
              onTap: () => context.copyToClipboard(order?.id ?? ''),
              title: context.loc.providerId(_getProviderTitle(order, swapPair)),
              contentWidget: Text(
                order?.id ?? '',
                style: AquaAddressTypography.body2.copyWith(
                  color: context.aquaColors.textPrimary,
                ),
              ),
              iconTrailing: AquaIcon.copy(
                size: 18,
                color: context.aquaColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getProviderTitle(SwapOrder? order, SwapPair swapPair) {
    if (order == null) return '';

    final deliverAsset = swapPair.from.toAsset();
    final providerName = deliverAsset.providerName;

    return providerName.isNotEmpty
        ? providerName
        : order.serviceType.displayName;
  }
}
