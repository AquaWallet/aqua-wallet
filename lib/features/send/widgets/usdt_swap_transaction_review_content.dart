import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class UsdSwapTransactionReviewContent extends ConsumerWidget {
  const UsdSwapTransactionReviewContent({
    super.key,
    required this.args,
    required this.transactionType,
  });

  final SendAssetArguments args;
  final SendTransactionType transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sendAssetInputStateProvider(args)).value!;
    final fees = ref
        .watch(transactionFeeStructureProvider(
          FeeStructureArguments.usdtSwap(sendAssetArgs: args),
        ))
        .valueOrNull
        ?.mapOrNull(usdtSwap: (model) => model);

    final formatter = ref.read(formatProvider);

    // For USDt, format the actual USDt amount (stored in input.amount as satoshis)
    final usdtCryptoAmount = formatter.formatAssetAmount(
      asset: input.asset,
      amount: input.amount,
      displayUnitOverride:
          SupportedDisplayUnits.fromAssetInputUnit(input.inputUnit),
      removeTrailingZeros: input.asset.isNonSatsAsset,
    );

    return Column(
      children: [
        //ANCHOR - Send Summary
        AquaTransactionSummary.send(
          assetId: input.asset.id,
          assetTicker: input.asset.ticker,
          assetIconUrl: input.asset.logoUrl,
          amountCrypto: '-$usdtCryptoAmount',
          amountFiat: '',
          colors: context.aquaColors,
        ),
        const SizedBox(height: 20),
        //ANCHOR - Recipient & Note Card
        _RecipientAndFeeCard(
          fees: fees,
          address: input.addressFieldText,
        ),
        const SizedBox(height: 16),
        //ANCHOR - Order ID Card
        _OrderIdCard(
          fees: fees,
          args: SwapArgs(pair: input.swapPair!),
        ),
        const SizedBox(height: 24),
        //ANCHOR - Fee Selection Card
        LiquidFeeSelector(args: args),
        const SizedBox(height: kBottomNavigationBarHeight),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _RecipientAndFeeCard extends StatelessWidget {
  const _RecipientAndFeeCard({
    required this.fees,
    required this.address,
  });

  final USDtSwapFee? fees;
  final String? address;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: fees == null,
      child: AquaCard.surface(
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            //ANCHOR - Recipient Address
            AquaListItem(
              title: context.loc.recipient,
              onTap: address != null
                  ? () => context.copyToClipboard(address!)
                  : null,
              contentWidget: AquaColoredText(
                text: address ?? '',
                maxLines: 2,
                style: AquaAddressTypography.body2.copyWith(
                  color: context.aquaColors.textSecondary,
                ),
                colorType: ColoredTextEnum.coloredIntegers,
              ),
              iconTrailing: AquaIcon.copy(
                size: 18,
                color: context.aquaColors.textSecondary,
              ),
            ),
            Divider(
              height: 4,
              thickness: 1,
              color: context.aquaColors.surfaceSecondary,
            ),
            //ANCHOR - Total Fee
            AquaListItem(
              title: context.loc.totalFees,
              titleTrailing: fees?.totalFeesCrypto ?? '',
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderIdCard extends ConsumerWidget {
  const _OrderIdCard({
    required this.args,
    required this.fees,
  });

  final SwapArgs args;
  final USDtSwapFee? fees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapService = ref.watch(preferredUsdtSwapServiceProvider).valueOrNull;
    final order = ref.watch(swapOrderProvider(args)).valueOrNull?.order;
    final orderId = order?.id;
    final feePercentage = fees?.serviceFeePercentage.toStringAsFixed(1);

    return Skeletonizer(
      enabled: order == null,
      child: Column(
        children: [
          Skeleton.keep(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AquaText.body1SemiBold(
                  text: context.loc
                      .serviceSwapDetails(args.pair.to.toAsset().network),
                ),
                AquaIcon.infoCircle(
                  onTap: () {},
                  padding: EdgeInsets.zero,
                  color: context.aquaColors.textPrimary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AquaCard.surface(
            elevation: 0,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                //ANCHOR - Service Provider
                AquaListItem(
                  title: context.loc.provider,
                  subtitleTrailing: swapService?.displayName ?? '',
                ),
                Divider(
                  height: 4,
                  thickness: 1,
                  color: context.aquaColors.surfaceSecondary,
                ),
                //ANCHOR - Order Id
                AquaListItem(
                  onTap: orderId != null
                      ? () => context.copyToClipboard(orderId)
                      : null,
                  title: context.loc.serviceId(swapService?.displayName ?? ''),
                  contentWidget: Text(
                    orderId ?? '',
                    style: AquaAddressTypography.body2.copyWith(
                      color: context.aquaColors.textPrimary,
                    ),
                  ),
                  iconTrailing: Skeleton.unite(
                    child: AquaIcon.copy(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                  ),
                ),
                Divider(
                  height: 4,
                  thickness: 1,
                  color: context.aquaColors.surfaceSecondary,
                ),
                //ANCHOR - Service Fee
                AquaListItem(
                  title: context.loc.serviceFee,
                  subtitleTrailing:
                      feePercentage != null ? '$feePercentage%' : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
