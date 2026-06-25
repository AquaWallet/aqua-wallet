import 'package:aqua/common/common.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

//TODO - Ad-hoc solution, should revisit once more services are added
enum SendTransactionType { send, topUp, privateKeySweep, deepLink }

class SendAssetReviewPage extends HookConsumerWidget
    with GenericErrorPromptMixin {
  const SendAssetReviewPage({
    super.key,
    required this.args,
    required this.onConfirmed,
    this.onErrorButtonTap,
  });

  final SendAssetArguments args;
  final VoidCallback onConfirmed;
  final VoidCallback? onErrorButtonTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupInitialized =
        ref.watch(sendAssetSetupProvider(args)).valueOrNull ?? false;

    final createInitialTransaction = useCallback(() => ref
        .read(sendAssetTxnProvider(args).notifier)
        .createFeeEstimateTransaction());

    final transactionType = ref.watch(
      sendAssetInputStateProvider(args).select(
        (state) =>
            state.valueOrNull?.transactionType ?? SendTransactionType.send,
      ),
    );

    final swapOrderReady = ref.watch(sendAssetSwapOrderReadyProvider(args));

    final resolvedAsset = ref.watch(sendAssetInputStateProvider(args)
            .select((s) => s.valueOrNull?.asset)) ??
        args.asset;

    useEffect(() {
      if (setupInitialized && swapOrderReady) {
        createInitialTransaction();
      }
      return null;
    }, [setupInitialized, swapOrderReady]);

    ref
      ..listen(sendAssetInputStateProvider(args), (prev, curr) {
        final wasBoltzToBoltz = prev?.valueOrNull?.isBoltzToBoltzSwap ?? false;
        final isBoltzToBoltzNow = curr.valueOrNull?.isBoltzToBoltzSwap ?? false;
        if (!wasBoltzToBoltz && isBoltzToBoltzNow) {
          AquaTooltip.show(
            context,
            message: context.loc.lightningSendTooltip,
            colors: context.aquaColors,
            maxLines: 2,
            variant: AquaTooltipVariant.normal,
            onToolTipTap: () => ref
                .read(launchUrlProvider.notifier)
                .launchUrl(constants.jan3AquatoAquaTransactionsInfoUrl),
          );
        }
      })
      ..listen(sendAssetInputStateProvider(args), (prev, curr) {
        if (curr.valueOrNull?.feeAsset != prev?.valueOrNull?.feeAsset &&
            !curr.isLoading) {
          final isReady = ref.read(sendAssetSwapOrderReadyProvider(args));
          if (isReady) {
            createInitialTransaction();
          }
        }
      })
      ..listen(sendAssetSetupProvider(args), (_, value) {
        showGenericErrorPromptOnAsyncError(
          context,
          value,
          onPrimaryButtonTap: onErrorButtonTap,
        );
      })
      ..listen(sendAssetTxnProvider(args), (_, value) {
        showGenericErrorPromptOnAsyncError(
          context,
          value,
          onPrimaryButtonTap: onErrorButtonTap,
        );
      });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: switch (resolvedAsset) {
              _ when (resolvedAsset.isBTC || resolvedAsset.isLiquid) =>
                AquaTransactionReviewContent(
                  args: args,
                  onFeeError: onErrorButtonTap,
                ),
              _ when (resolvedAsset.isLightning) =>
                LightningTransactionReviewContent(args),
              _ when (resolvedAsset.isAltUsdt) =>
                UsdSwapTransactionReviewContent(
                  args: args,
                  transactionType: transactionType,
                  onFeeError: onErrorButtonTap,
                ),
              _ => const SizedBox.shrink(),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SendConfirmationSlider(
            args: args,
            onConfirmed: onConfirmed,
          ),
        ),
      ],
    );
  }
}
