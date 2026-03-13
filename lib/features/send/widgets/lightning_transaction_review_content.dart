import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

const _fakeLightningInvoice = ''
    'lnbc10u1pn7l5s8sp5wwzy3m5w26q3flj9xdxaakxmj0mqvq7sznml46ga7gyma7ucnj2spp5lf';

class LightningTransactionReviewContent extends HookConsumerWidget {
  const LightningTransactionReviewContent(this.args, {super.key});

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.read(sendAssetInputStateProvider(args)).value!;

    final unit = SupportedDisplayUnits.fromAssetInputUnit(input.inputUnit);
    final ticker = input.asset.getDisplayTicker(unit);
    final formatAmountForDisplay = ref.read(formatProvider).formatAssetAmount(
          asset: input.asset,
          amount: input.amount,
          displayUnitOverride: unit,
        );

    //NOTE - We can not rely on the addressFieldText value for fiat amount
    //because lightning invoices can update the text field value which comes
    //back in sats
    final fiatAmount = useMemoized(() {
      if (input.isFiatAmountInput && input.amount > 0) {
        final fiatRate = ref
                .read(fiatRatesProvider)
                .valueOrNull
                ?.firstWhereOrNull((r) => r.code == input.rate.currency.value)
                ?.rate ??
            0;

        final btcAmount = input.amount / SupportedDisplayUnits.btc.satsPerUnit;
        final fiatValue = fiatRate != 0 ? btcAmount * fiatRate : 0.0;

        return ref.read(formatProvider).formatFiatAmount(
              amount: DecimalExt.fromDouble(fiatValue),
              specOverride: input.rate.currency.format,
              withSymbol: false,
            );
      }

      return "0.00";
    }, [input.isFiatAmountInput, input.amount, input.rate.currency.value]);

    return Column(
      children: [
        //ANCHOR - Send Summary
        AquaTransactionSummary.send(
          assetId: input.asset.id,
          assetTicker: input.isFiatAmountInput ? '' : ticker,
          amountCrypto: input.isFiatAmountInput
              ? '-${input.rate.currency.format.symbol}$fiatAmount'
              : '-$formatAmountForDisplay',
          amountFiat: input.displayConversionAmount != null
              ? input.isFiatAmountInput
                  ? '-$formatAmountForDisplay $ticker'
                  : '-${input.displayConversionAmount!}'
              : '',
          colors: context.aquaColors,
        ),
        const SizedBox(height: 16),
        //ANCHOR - Aqua Fee Card
        _RecipientAndFeeCard(args: args),
        const SizedBox(height: 18),
        const _OrderIdCard(),
      ],
    );
  }
}

class _RecipientAndFeeCard extends ConsumerWidget {
  const _RecipientAndFeeCard({required this.args});

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = Asset.lbtc();
    final input = ref.watch(sendAssetInputStateProvider(args)).value!;
    final feesModel =
        ref.watch(transactionFeeStructureProvider(args.toFeeStructureArgs()));
    final fees = feesModel.valueOrNull?.mapOrNull(boltzSend: (f) => f);

    final address = input.addressFieldText;
    final feeSats = fees?.estimatedOnchainFee ?? 0;
    final feeFiat =
        ref.watch(satsToFiatDisplayWithSymbolProvider(feeSats)).value;
    final unit = SupportedDisplayUnits.fromAssetInputUnit(input.inputUnit);
    final feeCrypto = ref.watch(formatProvider).formatAssetAmount(
          amount: feeSats,
          asset: asset,
          displayUnitOverride: unit,
        );
    final ticker = asset.getDisplayTicker(unit);
    final feePercent = (fees?.swapFeePercentage ?? 0) * 100;
    final feeRate = (fees?.onchainFeeRate ?? 0) / kVbPerKb;
    final showSkeleton = feesModel.isLoading || fees == null;

    return Skeletonizer(
      enabled: showSkeleton,
      child: AquaCard.surface(
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            //ANCHOR - Address
            if (address != null) ...[
              AquaListItem(
                title: context.loc.recipient,
                onTap: () => context.copyToClipboard(address),
                contentWidget: Skeleton.replace(
                  replace: showSkeleton,
                  replacement: const AquaColoredText(
                    text: _fakeLightningInvoice,
                    maxLines: 2,
                    style: AquaAddressTypography.body2,
                  ),
                  child: AquaColoredText(
                    text: address,
                    maxLines: 2,
                    style: AquaAddressTypography.body2.copyWith(
                      color: context.aquaColors.textSecondary,
                    ),
                    shouldWrap: true,
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
            ],
            //ANCHOR - Total Fee
            AquaListItem(
              title: context.loc.totalFees,
              titleTrailing: showSkeleton || feeFiat == null ? '-' : feeFiat,
              subtitleTrailing: '$feeCrypto $ticker',
            ),
            Divider(
              height: 4,
              thickness: 1,
              color: context.aquaColors.surfaceSecondary,
            ),
            //ANCHOR - Service Fee
            AquaListItem(
              title: context.loc.boltzServiceFee,
              subtitleTrailing: '$feePercent%',
            ),
            Divider(
              height: 4,
              thickness: 1,
              color: context.aquaColors.surfaceSecondary,
            ),
            //ANCHOR - Service Fee
            AquaListItem(
              title: context.loc.currentLiquidRate,
              subtitleTrailing: context.loc.satsPerVByte(feeRate),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderIdCard extends ConsumerWidget {
  const _OrderIdCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(boltzSubmarineSwapProvider);
    final orderId = order?.id;

    return Skeletonizer(
      enabled: order == null,
      child: Column(
        children: [
          Skeleton.keep(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AquaText.body1SemiBold(
                  text: context.loc.lightningSwapDetails,
                ),
                AquaIcon.infoCircle(
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
                  onTap: () => ref.read(urlLauncherProvider).open(boltzWebsite),
                  title: context.loc.provider,
                  subtitleTrailing: 'Boltz',
                  subtitleTrailingColor: context.aquaColors.accentBrand,
                  iconTrailing: Skeleton.unite(
                    child: AquaIcon.externalLink(
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
                //ANCHOR - Order Id
                AquaListItem(
                  onTap: orderId != null
                      ? () => context.copyToClipboard(orderId)
                      : null,
                  title: context.loc.boltzId,
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
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
