import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

//TODO - Ad-hoc solution, should revisit once more services are added
enum SendTransactionType { send, topUp, privateKeySweep }

class SendAssetReviewPage extends HookConsumerWidget
    with GenericErrorPromptMixin {
  const SendAssetReviewPage({
    super.key,
    required this.onConfirmed,
    required this.arguments,
  });

  final VoidCallback onConfirmed;
  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupInitialized =
        ref.watch(sendAssetSetupProvider(arguments)).valueOrNull ?? false;

    final createInitialTransaction = useCallback(() => ref
        .read(sendAssetTxnProvider(arguments).notifier)
        .createFeeEstimateTransaction());

    final transactionType = ref.watch(
      sendAssetInputStateProvider(arguments).select(
        (state) =>
            state.valueOrNull?.transactionType ?? SendTransactionType.send,
      ),
    );

    useEffect(() {
      if (setupInitialized) {
        createInitialTransaction();
      }
      return null;
    }, [setupInitialized]);

    ref.listen(sendAssetInputStateProvider(arguments), (prev, curr) {
      if (curr.valueOrNull?.feeAsset != prev?.valueOrNull?.feeAsset &&
          !curr.isLoading) {
        createInitialTransaction();
      }
    });

    ref.listen(sendAssetSetupProvider(arguments), (_, value) {
      showGenericErrorPromptOnAsyncError(context, value);
    });

    ref.listen(sendAssetTxnProvider(arguments), (_, value) {
      showGenericErrorPromptOnAsyncError(context, value);
    });

    return _TransactionReviewContent(
      args: arguments,
      transactionType: transactionType,
      onConfirmed: onConfirmed,
    );
  }
}

class _TransactionReviewContent extends StatelessWidget {
  const _TransactionReviewContent({
    required this.args,
    required this.transactionType,
    required this.onConfirmed,
  });

  final SendAssetArguments args;
  final SendTransactionType transactionType;
  final VoidCallback onConfirmed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        //ANCHOR - Transaction Review Content
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(
            left: 28,
            right: 28,
            top: 32,
            bottom: 140,
          ),
          child: switch (args.asset) {
            _ when (args.asset.isBTC || args.asset.isLiquid) =>
              _AquaTxnReviewContent(
                args: args,
              ),
            _ when (args.asset.isLightning) => LightningTxnReviewContent(args),
            _ when (args.asset.isAltUsdt) => _UsdSwapTxnReviewContent(
                args: args,
                transactionType: transactionType,
              ),
            _ => const SizedBox.shrink(),
          },
        ),
        //ANCHOR - Bottom Fade Effect
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: MediaQuery.sizeOf(context).height * .25,
            decoration: BoxDecoration(
              gradient: Theme.of(context).getFadeGradient(),
            ),
          ),
        ),
        //ANCHOR - Transaction Execution Slider
        Container(
          alignment: Alignment.bottomCenter,
          margin: const EdgeInsets.only(bottom: 28),
          child: SendConfirmationSlider(
            args: args,
            onConfirmed: onConfirmed,
          ),
        ),
      ],
    );
  }
}

class _AquaTxnReviewContent extends ConsumerWidget {
  const _AquaTxnReviewContent({
    required this.args,
  });

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transaction = ref.watch(sendAssetTxnProvider(args)).value;
    final input = ref.watch(sendAssetInputStateProvider(args)).valueOrNull;
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));

    if (input == null) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        //ANCHOR - Send Review Card
        // TODO: Deduct fee from displayed receive amount when sending all
        SendAssetReviewInfoCard(
          asset: input.asset,
          address: input.addressFieldText ?? '-',
          amount: input.amount.toString(),
          isSendAll: input.isSendAllFunds,
          transactionType: input.transactionType,
        ),
        //ANCHOR - Fee Selection Card
        if (transaction != null && args.asset.isUsdtLiquid) ...{
          const SizedBox(height: 22),
          LiquidFeeSelector(args: args)
        } else ...{
          ...?transaction?.whenOrNull(
            created: (t) => [
              const SizedBox(height: 22),
              switch (args.asset) {
                _ when (args.asset.isBTC) => BitcoinFeeSelector(args: args),
                _ when (args.asset.isLiquid) => LiquidFeeSelector(args: args),
                _ => const SizedBox.shrink(),
              }
            ],
          ),
        },
        const SizedBox(height: 22),
        //ANCHOR - Add Note
        if (isNotesEnabled) ...{
          const AddNoteButton(),
        },
      ],
    );
  }
}

class _UsdSwapTxnReviewContent extends ConsumerWidget {
  const _UsdSwapTxnReviewContent({
    required this.args,
    required this.transactionType,
  });

  final SendAssetArguments args;
  final SendTransactionType transactionType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sendAssetInputStateProvider(args)).value!;
    final swapState = ref
        .watch(swapOrderProvider(SwapArgs(pair: input.swapPair!)))
        .valueOrNull;
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));

    return Column(
      children: [
        //ANCHOR - Send Review Card
        Text(
          context.loc.sendAssetReviewScreenGenericLabel(
            input.asset.network,
            input.asset.displayName,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 20),
        SendAssetReviewInfoCard(
          asset: input.asset,
          address: input.addressFieldText ?? '-',
          amount: input.amount.toString(),
          isSendAll: input.isSendAllFunds,
          swapOrderId: swapState?.order?.id ?? '-',
          transactionType: transactionType,
        ),
        const SizedBox(height: 22),
        //ANCHOR - Fee Breakdown Card
        TransactionFeeBreakdownCard(
          args: FeeStructureArguments.usdtSwap(
            sendAssetArgs: args,
          ),
        ),
        const SizedBox(height: 22.0),
        //ANCHOR - Add Note
        if (isNotesEnabled) ...{
          const AddNoteButton(),
        },
      ],
    );
  }
}
