import 'package:aqua/config/config.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';

class SendAssetReviewInfoCard extends HookConsumerWidget {
  const SendAssetReviewInfoCard({
    super.key,
    required this.amount,
    this.isSendAll = false,
    required this.asset,
    required this.address,
    this.swapOrderId,
    this.transactionType = SendTransactionType.send,
  });

  final String amount;
  final bool isSendAll;
  final Asset asset;
  final String address;
  final String? swapOrderId;
  final SendTransactionType transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowCard(
      color: Theme.of(context).colors.altScreenSurface,
      borderRadius: BorderRadius.circular(12.0),
      bordered: !darkMode,
      borderColor: context.colors.cardOutlineColor,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                //ANCHOR - Logo
                AssetIcon(
                  assetId: asset.id,
                  assetLogoUrl: asset.logoUrl,
                  size: 51.0,
                ),
                const SizedBox(width: 19.0),
                //ANCHOR - Amount Details
                switch (transactionType) {
                  SendTransactionType.send => _SendTransactionAmountDetails(
                      amount: amount,
                      asset: asset,
                      isSendAll: isSendAll,
                    ),
                  SendTransactionType.topUp => _TopUpTransactionAmountDetails(
                      amount: amount,
                      asset: asset,
                    ),
                },
              ],
            ),
            if (!asset.isLightning) ...[
              Divider(
                  color: context.colors.horizontalDivider,
                  thickness: 1,
                  height: 33.0),
              //ANCHOR - Address
              LabelCopyableTextView(
                label: context.loc.sendTo,
                value: address,
              ),
              //ANCHOR - Divider
              DashedDivider(
                height: 36.0,
                thickness: 2.0,
                color: Theme.of(context).colors.divider,
              ),
              if (asset.isAltUsdt) ...[
                const SizedBox(height: 16.0),
                //ANCHOR - Swap Id
                LabelCopyableTextView(
                  label: context.loc.swapId,
                  value: swapOrderId ?? '',
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _SendTransactionAmountDetails extends HookConsumerWidget {
  const _SendTransactionAmountDetails({
    required this.isSendAll,
    required this.amount,
    required this.asset,
  });

  final bool isSendAll;
  final String amount;
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(asset)));
    final title = isSendAll || asset.isLightning || asset.isAltUsdt
        ? context.loc.sendAssetReviewScreenConfirmAmountTitleSend
        : context.loc.sendAssetReviewScreenConfirmAmountTitleReceive;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2.0),
        //ANCHOR - Amount Title
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8.0),
        //ANCHOR - Amount & Symbol
        AssetCryptoAmount(
          forceVisible: true,
          forceDisplayUnit: displayUnit,
          amount: amount,
          asset: asset,
          style: context.textTheme.headlineSmall,
        ),
      ],
    );
  }
}

class _TopUpTransactionAmountDetails extends HookConsumerWidget {
  const _TopUpTransactionAmountDetails({
    required this.amount,
    required this.asset,
  });

  final String amount;
  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(topUpInputStateProvider).value!;
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(asset)));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2.0),
        //ANCHOR - Amount Title
        Text(
          context.loc.youWillTopUp,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        if (asset.isAnyUsdt) ...{
          //ANCHOR - Amount & Symbol
          AssetCryptoAmount(
            forceVisible: true,
            forceDisplayUnit: displayUnit,
            amount: input.amount.toString(),
            asset: asset,
            style: const TextStyle(
              fontSize: 22,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
            unitStyle: const TextStyle(
              fontSize: 22,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        } else ...{
          //ANCHOR - USD Amount
          Text(
            '\$${input.amountInUsd}',
            style: const TextStyle(
              fontSize: 22,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          //ANCHOR - Amount & Symbol
          AssetCryptoAmount(
            forceVisible: true,
            forceDisplayUnit: displayUnit,
            amount: amount,
            asset: asset,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.topUpTransactionAmountSubtitleColor,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
            unitStyle: TextStyle(
              fontSize: 14,
              color: context.colors.topUpTransactionAmountSubtitleColor,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        },
      ],
    );
  }
}
