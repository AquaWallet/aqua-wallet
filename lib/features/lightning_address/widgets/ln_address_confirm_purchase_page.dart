import 'package:aqua/data/data.dart';
import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

const _kConfirmPurchasePlaceholderAmount = '0.08';

class LnAddressConfirmPurchasePage extends HookConsumerWidget {
  const LnAddressConfirmPurchasePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(lnAddressEditInputProvider).valueOrNull;
    final payWithLbtc = form?.selectedAsset?.isLBTC ?? false;
    final usernameUpdateProduct =
        ref.watch(lnUsernameUpdateProductProvider).valueOrNull;
    final paymentRequestAsync = ref.watch(lnAddressPaymentRequestProvider);
    final args = paymentRequestAsync.valueOrNull?.args;
    final isSubmitting = ref.watch(lnAddressUpdatePaymentProvider).isLoading;

    final sendInputReady =
        args != null && ref.watch(sendAssetInputStateProvider(args)).hasValue;

    final isConfirmPageReady = usernameUpdateProduct != null &&
        paymentRequestAsync.hasValue &&
        sendInputReady;

    final createFeeEstimate = useCallback(() {
      final a = args;
      if (a != null) {
        ref
            .read(sendAssetTxnProvider(a).notifier)
            .createFeeEstimateTransaction();
      }
    }, [args]);

    useEffect(() {
      if (!isConfirmPageReady) return null;
      createFeeEstimate();
      return null;
    }, [isConfirmPageReady, createFeeEstimate]);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: isConfirmPageReady
                  ? _LnConfirmLoadedBody(
                      args: args,
                      usernameUpdateProduct: usernameUpdateProduct,
                      payWithLbtc: payWithLbtc,
                    )
                  : const _LnConfirmSkeletonBody(),
            ),
          ),
          if (isConfirmPageReady)
            _LnConfirmFeeAssetListener(
              args: args,
              onFeeAssetChanged: createFeeEstimate,
            ),
          const SizedBox(height: 12),
          AquaSlider(
            width: MediaQuery.sizeOf(context).width - 32,
            onConfirm: () =>
                ref.read(lnAddressUpdatePaymentProvider.notifier).submit(),
            text: context.loc.lnAddressEditSlideToChange,
            enabled: isConfirmPageReady && !isSubmitting,
            stickToEnd: false,
            colors: context.aquaColors,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// [ref.listen] is valid on [LnAddressConfirmPurchasePage] too; this zero-size child
/// keeps the fee-asset subscription next to the `isConfirmPageReady` branch only.
class _LnConfirmFeeAssetListener extends ConsumerWidget {
  const _LnConfirmFeeAssetListener({
    required this.args,
    required this.onFeeAssetChanged,
  });

  final SendAssetArguments args;
  final VoidCallback onFeeAssetChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sendAssetInputStateProvider(args), (prev, curr) {
      if (curr.valueOrNull?.feeAsset != prev?.valueOrNull?.feeAsset &&
          !curr.isLoading) {
        onFeeAssetChanged();
      }
    });
    return const SizedBox.shrink();
  }
}

class _LnConfirmSkeletonBody extends StatelessWidget {
  const _LnConfirmSkeletonBody();

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaTransactionSummary.send(
            assetId: AssetIds.layer2,
            assetTicker: '',
            amountCrypto: _kConfirmPurchasePlaceholderAmount,
            amountFiat: _kConfirmPurchasePlaceholderAmount,
            colors: context.aquaColors,
          ),
          const SizedBox(height: 16),
          AquaCard.surface(
            elevation: 0,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              children: [
                AquaListItem(
                  title: context.loc.newLightningAddress,
                  subtitle: 'lnaddress@aquawallet.io',
                ),
                const LnAddressTotalFeesRow(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AquaText.body2Medium(
            color: context.aquaColors.textSecondary,
            maxLines: 2,
            textAlign: TextAlign.center,
            text: context.loc.lightningAddressChangeWarning,
          ),
          const SizedBox(height: 24),
          const _LnConfirmFeeSelectorPlaceholder(),
        ],
      ),
    );
  }
}

class _LnConfirmFeeSelectorPlaceholder extends StatelessWidget {
  const _LnConfirmFeeSelectorPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: AquaCard.surface(
              elevation: 0,
              borderRadius: BorderRadius.circular(8),
              child: const Center(
                child: AquaText.body2Medium(text: 'L-BTC'),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AspectRatio(
            aspectRatio: 1.0,
            child: AquaCard.surface(
              elevation: 0,
              borderRadius: BorderRadius.circular(8),
              child: const Center(
                child: AquaText.body2Medium(text: 'USDt'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LnConfirmLoadedBody extends ConsumerWidget {
  const _LnConfirmLoadedBody({
    required this.args,
    required this.usernameUpdateProduct,
    required this.payWithLbtc,
  });

  final SendAssetArguments args;
  final LiquidWalletProduct usernameUpdateProduct;
  final bool payWithLbtc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(lnAddressEditInputProvider).valueOrNull;
    final selectedAsset = form?.selectedAsset;
    final assetId = selectedAsset?.isLBTC == true
        ? AssetIds.layer2
        : selectedAsset?.id ?? '';
    final formatter = ref.read(formatProvider);
    final displayUnits = ref.read(displayUnitsProvider);
    final amounts = buildLnUsernameChangeConfirmSummaryAmounts(
      usernameUpdateProduct: usernameUpdateProduct,
      payWithLbtc: payWithLbtc,
      formatter: formatter,
      displayUnits: displayUnits,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AquaTransactionSummary.send(
          assetId: assetId,
          assetTicker: selectedAsset?.ticker ?? '',
          amountCrypto: amounts.amountCrypto,
          amountFiat: amounts.amountFiat,
          colors: context.aquaColors,
        ),
        const SizedBox(height: 16),
        AquaCard.surface(
          elevation: 0,
          borderRadius: BorderRadius.circular(8),
          child: Column(
            children: [
              AquaListItem(
                title: context.loc.newLightningAddress,
                subtitle: form?.newAddress ?? 'lnaddress@aquawallet.io',
              ),
              const LnAddressTotalFeesRow(),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AquaText.body2Medium(
          color: context.aquaColors.textSecondary,
          maxLines: 2,
          textAlign: TextAlign.center,
          text: context.loc.lightningAddressChangeWarning,
        ),
        const SizedBox(height: 24),
        LiquidFeeSelector(args: args),
      ],
    );
  }
}
