import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

//TODO - Ad-hoc solution, should revisit once more services are added
enum SendTransactionType { send, topUp, privateKeySweep }

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

    useEffect(() {
      if (setupInitialized && swapOrderReady) {
        createInitialTransaction();
      }
      return null;
    }, [setupInitialized, swapOrderReady]);

    ref
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

    return SafeArea(
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, viewportConstraints) => ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  //ANCHOR - Transaction Review Content
                  child: switch (args.asset) {
                    _ when (args.asset.isBTC || args.asset.isLiquid) =>
                      AquaTransactionReviewContent(
                        args: args,
                        onFeeError: onErrorButtonTap,
                      ),
                    _ when (args.asset.isLightning) =>
                      LightningTransactionReviewContent(args),
                    _ when (args.asset.isAltUsdt) =>
                      UsdSwapTransactionReviewContent(
                        args: args,
                        transactionType: transactionType,
                        onFeeError: onErrorButtonTap,
                      ),
                    _ => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ),
          //ANCHOR - Transaction Execution Slider
          Container(
            alignment: Alignment.bottomCenter,
            margin: const EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: 12,
            ),
            child: SendConfirmationSlider(
              args: args,
              onConfirmed: onConfirmed,
            ),
          ),
        ],
      ),
    );
  }
}
