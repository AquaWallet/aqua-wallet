import 'package:aqua/common/widgets/link_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/transactions/widgets/transaction_note_editor.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

final _logger = CustomLogger(FeatureFlag.tx);

class AssetTransactionDetailsScreen extends StatelessWidget {
  static const routeName = '/assetTransactionDetailsScreen';

  const AssetTransactionDetailsScreen({super.key, required this.arguments});
  final TransactionUiModel arguments;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.0,
        onActionButtonPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: arguments.map(
          normal: (model) => _NormalTransactionDetails(txnUiModel: model),
          ghost: (model) => _GhostTransactionDetails(txnUiModel: model),
        ),
      ),
    );
  }
}

class _GhostTransactionDetails extends HookConsumerWidget {
  const _GhostTransactionDetails({
    required this.txnUiModel,
  });

  final GhostTransactionUiModel txnUiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionProvider = useMemoized(
      () => ghostTransactionDetailsProvider((context, txnUiModel)),
    );

    final transaction = ref.watch(transactionProvider);

    ref.listen(transactionsProvider(txnUiModel.asset), (_, __) {
      ref.invalidate(transactionProvider);
    });

    return transaction.when(
      data: (detailsUiModel) => _TransactionDetailsContent(
        txnUiModel: txnUiModel,
        detailsUiModel: detailsUiModel,
        onRefresh: ref.read(transactionProvider.notifier).refresh,
      ),
      loading: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
            Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
      ),
      error: (_, __) => Center(
        child: GenericErrorWidget(
          buttonTitle: context.loc.assetTransactionDetailsErrorButton,
          buttonAction: () {
            context.pop();
          },
        ),
      ),
    );
  }
}

class _NormalTransactionDetails extends HookConsumerWidget {
  const _NormalTransactionDetails({
    required this.txnUiModel,
  });

  final NormalTransactionUiModel txnUiModel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionProvider =
        assetTransactionDetailsProvider((context, txnUiModel));

    final transactionFromStorage = ref
        .watch(transactionStorageProvider)
        .asData
        ?.value
        .firstWhereOrNull((tx) => tx.txhash == txnUiModel.transaction.txhash);

    final transaction = ref.watch(transactionProvider);

    final showInsufficientFundsSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        backgroundColor: Theme.of(context).colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height *
              context.adaptiveDouble(
                mobile: 0.4,
                tablet: 0.2,
              ),
        ),
        builder: (_) => const InsufficientBalanceSheet(),
      );
    }, []);

    useEffect(() {
      final subscription = ref
          .read(txnUiModel.asset.isBTC ? bitcoinProvider : liquidProvider)
          .blockHeightEventSubject
          .stream
          .listen((lastBlock) {
        ref.read(transactionProvider.notifier).refresh();
      });

      return subscription.cancel;
    }, []);

    useEffect(() {
      if (txnUiModel.isRbfSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            backgroundColor: Theme.of(context).colors.background,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
            ),
            builder: (_) => const RbfSuccessSheet(),
          );
        });
      }
      return null;
    }, []);

    ref.listen(transactionsProvider(txnUiModel.asset), (previous, next) {
      ref.invalidate(transactionProvider);
    });

    ref.listen(bitcoinRbfProvider(txnUiModel.transaction), (prev, next) {
      if (next.error is GdkNetworkInsufficientFunds ||
          next.error is GdkNetworkInsufficientFundsForFee) {
        showInsufficientFundsSheet();
        return;
      }
      final txnHash = next.valueOrNull;
      if (txnHash != null && txnHash != prev?.valueOrNull) {
        _logger.debug('[RBF] Replacing transaction with hash: $txnHash');
        context.pushReplacement(
          AssetTransactionDetailsScreen.routeName,
          extra: txnUiModel.copyWith(
            isRbfSuccess: true,
            transaction: txnUiModel.transaction.copyWith(txhash: txnHash),
          ),
        );
      }
    });

    final showCustomFeeInputSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        builder: (_) => CustomBitcoinFeeInputSheet(
          title: context.loc.assetTransactionDetailsReplaceByFeeInputTitle,
          // original transaction fee (in sats per vb) + 1 sat
          minFeeRate: (txnUiModel.transaction.feeRate! ~/ kVbPerKb) + 1,
          transactionVsize: txnUiModel.transaction.transactionVsize!,
          onConfirm: (fee) => ref
              .read(bitcoinRbfProvider(txnUiModel.transaction).notifier)
              .createRbfTransaction(fee.feeRate),
        ),
      );
    }, []);

    return transaction.maybeWhen(
      data: (detailsUiModel) => _TransactionDetailsContent(
        txnUiModel: txnUiModel.copyWith(dbTransaction: transactionFromStorage),
        detailsUiModel:
            detailsUiModel.copyWith(dbTransaction: transactionFromStorage),
        onRbfButtonPress: showCustomFeeInputSheet,
        onRefresh: ref.read(transactionProvider.notifier).refresh,
      ),
      //TODO: Fix transaction details momentarily crashes due to RBF txn delay
      orElse: () => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(
            Theme.of(context).colorScheme.secondaryContainer,
          ),
        ),
      ),
      // error: (e, __) => Center(
      //   child: GenericErrorWidget(
      //     buttonTitle: context.loc.assetTransactionDetailsErrorButton,
      //     buttonAction: () {
      //       context.pop();
      //     },
      //   ),
      // ),
    );
  }
}

class _TransactionDetailsContent extends HookConsumerWidget {
  const _TransactionDetailsContent({
    required this.txnUiModel,
    required this.detailsUiModel,
    required this.onRefresh,
    this.onRbfButtonPress,
  });

  final TransactionUiModel txnUiModel;
  final AssetTransactionDetailsUiModel detailsUiModel;
  final VoidCallback? onRbfButtonPress;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNotesEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));

    final explorer =
        ref.watch(blockExplorerProvider.select((p) => p.currentBlockExplorer));
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));

    final showNoteBottomSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useSafeArea: true,
        backgroundColor: Theme.of(context).colors.background,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.0),
            topRight: Radius.circular(30.0),
          ),
        ),
        builder: (context) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: TransactionNoteEditor(
              txHash: detailsUiModel.transactionId,
              initialNote: detailsUiModel.dbTransaction?.note,
            ),
          ),
        ),
      );
    }, [detailsUiModel]);

    final isNonSwapTransaction = useMemoized(
      () => (TransactionDbModelType? type) {
        return !(type?.isBoltzSwap ?? false) &&
            !(type?.isPeg ?? false) &&
            !(type?.isUSDtSwap ?? false);
      },
      [],
    );

    return SmartRefresher(
      enablePullDown: true,
      key: refresherKey,
      controller: controller,
      physics: const BouncingScrollPhysics(),
      onRefresh: () {
        onRefresh();
        controller.refreshCompleted();
      },
      header: ClassicHeader(
        height: 40.0,
        refreshingText: '',
        releaseText: '',
        completeText: '',
        failedText: '',
        idleText: '',
        idleIcon: null,
        failedIcon: null,
        releaseIcon: null,
        completeIcon: const SizedBox.square(
          dimension: 28.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
          ),
        ),
        outerBuilder: (child) => Container(child: child),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            //ANCHOR - Transaction Type
            Text(
              detailsUiModel.type(context),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20.0),

            if ((detailsUiModel.dbTransaction?.type?.isBoltzSwap ?? false)) ...[
              //ANCHOR - Boltz Swap Transaction Details
              BoltzSwapDetailsCard(uiModel: detailsUiModel),
              //ANCHOR - Boltz Reverse Transaction Details
              BoltzReverseSwapDetailsCard(uiModel: detailsUiModel),
              const SizedBox(height: 20.0),
            ],

            //ANCHOR - Peg Transaction Details
            if ((detailsUiModel.dbTransaction?.type?.isPeg ?? false)) ...[
              SideswapPegDetailsCard(
                uiModel: detailsUiModel,
                arguments: txnUiModel,
              ),
              const SizedBox(height: 20.0),
            ],

            //ANCHOR - USDt Swap Transaction Details
            if ((detailsUiModel.dbTransaction?.isUSDtSwap ?? false)) ...[
              USDtSwapDetailsCard(
                uiModel: detailsUiModel,
                arguments: txnUiModel,
              ),
              const SizedBox(height: 20.0),
            ],

            //ANCHOR - General Transaction Details
            BoxShadowCard(
              color: Theme.of(context).colors.altScreenSurface,
              bordered: true,
              borderColor: Theme.of(context).colors.cardOutlineColor,
              borderRadius: BorderRadius.circular(12.0),
              child: Container(
                width: double.maxFinite,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...detailsUiModel.map(
                      swap: (item) => [
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionDetailsDelivered,
                          value:
                              '${item.deliverAmount} ${item.deliverAssetTicker}',
                        ),
                        const SizedBox(height: 18.0),
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionDetailsReceived,
                          value:
                              '${item.receiveAmount} ${item.receiveAssetTicker}',
                        ),
                      ],
                      redeposit: (item) => [
                        if (!item.isConfidential) ...[
                          TransactionDetailsDataItem(
                            title: context.loc.assetTransactionsTotalAmount,
                            value:
                                '${item.deliverAmount} ${item.deliverAssetTicker}',
                          ),
                          const SizedBox(height: 18.0),
                        ],
                        TransactionDetailsDataItem(
                          title: context.loc.networkFees,
                          value: '${item.feeAmount} ${item.feeAssetTicker}',
                        ),
                      ],
                      send: (item) => [
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionsTotalAmount,
                          value:
                              '${item.deliverAmount} ${item.deliverAssetTicker}',
                        ),
                        const SizedBox(height: 18.0),
                        TransactionDetailsDataItem(
                          title: context.loc.networkFees,
                          value: '${item.feeAmount} ${item.feeAssetTicker}',
                        ),
                      ],
                      receive: (item) => [
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionsTotalAmount,
                          value:
                              '${item.receivedAmount} ${item.receivedAssetTicker}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 18.0),
                    TransactionDetailsDataItem(
                      title: context.loc.date,
                      value: detailsUiModel.date,
                    ),
                    const SizedBox(height: 18.0),
                    TransactionDetailsDataItem(
                      title: context.loc.confimations,
                      value: detailsUiModel.formattedConfirmations,
                    ),
                    const SizedBox(height: 18.0),
                    LabelCopyableTextView(
                      label: context.loc.transactionID,
                      value: detailsUiModel.transactionId,
                    ),
                    const SizedBox(height: 18.0),
                    if (isNotesEnabled && txnUiModel.asset.isBTC) ...[
                      // Note section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.loc.note,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 4.0),
                                if (detailsUiModel
                                        .dbTransaction?.note?.isNotEmpty ??
                                    false)
                                  Text(
                                    detailsUiModel.dbTransaction!.note!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: 13.0,
                                        ),
                                  )
                                else
                                  GestureDetector(
                                    onTap: showNoteBottomSheet,
                                    child: Text(
                                      context.loc.addNoteScreenHint,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontSize: 13.0,
                                            color: Theme.of(context).hintColor,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (detailsUiModel.dbTransaction?.note?.isNotEmpty ??
                              false)
                            IconButton(
                              onPressed: () {
                                showNoteBottomSheet();
                              },
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                              ),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18.0),
                    ...detailsUiModel.maybeMap(
                      swap: (model) {
                        if (model.dbTransaction?.serviceAddress?.isNotEmpty ==
                            true) {
                          return [
                            LabelCopyableTextView(
                              label: context.loc.depositAddress,
                              value: model.dbTransaction!.serviceAddress!,
                            ),
                          ];
                        }
                        return [];
                      },
                      orElse: () => [],
                    ),
                    const SizedBox(height: 18.0),
                    // don't show the network tx status if swap, as the swap order status is shown instead
                    if (isNonSwapTransaction(
                        detailsUiModel.dbTransaction?.type)) ...[
                      Center(
                        child: TransactionDetailsStatusChip(
                          color: detailsUiModel.isPending
                              ? AquaColors.gray
                              : AquaColors.aquaGreen,
                          text: !detailsUiModel.isPending
                              ? context.loc.confirmed
                              : detailsUiModel.isDeliverLiquid
                                  ? context.loc.assetTransactionDetailsAccepted
                                  : context.loc.assetTransactionDetailsPending,
                        ),
                      ),
                      const SizedBox(height: 18.0),
                    ],
                    // Increase fee button
                    ...txnUiModel.maybeMap(
                      normal: (model) => (model.transaction.canRbf == true)
                          ? [
                              const SizedBox(height: 12.0),
                              Center(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.0),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      width: 1.0,
                                    ),
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: 12.0,
                                        ),
                                  ),
                                  onPressed: onRbfButtonPress,
                                  child: Text(context.loc.increaseFee),
                                ),
                              ),
                            ]
                          : [],
                      orElse: () => [],
                    ),
                    const SizedBox(height: 18.0),
                    if (!txnUiModel.isGhost) ...[
                      Center(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //ANCHOR - View transaction on explorer button
                            ButtonLink(
                                onPress: txnUiModel.mapOrNull(
                                  normal: (model) => () {
                                    final url = model.asset.isBTC
                                        ? explorer.btcUrl
                                        : explorer.liquidUrl;
                                    final link =
                                        '$url${model.transaction.txhash}';
                                    ref.read(urlLauncherProvider).open(link);
                                  },
                                ),
                                text: txnUiModel.asset.isLiquid
                                    ? context.loc
                                        .assetTransactionDetailsLiquidExplorerButton
                                    : context.loc
                                        .assetTransactionDetailsExplorerButton),
                            //ANCHOR - View unblinded transaction on explorer button
                            if (txnUiModel.asset.isLiquid) ...[
                              ButtonLink(
                                  onPress: txnUiModel.mapOrNull(
                                    normal: (model) => () {
                                      final link =
                                          '${explorer.liquidUrl}${model.blindingUrl}';
                                      ref.read(urlLauncherProvider).open(link);
                                    },
                                  ),
                                  text: context.loc
                                      .assetTransactionDetailsLiquidUnblindedExplorerButton),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}

class TransactionDetailsDataItem extends StatelessWidget {
  const TransactionDetailsDataItem({
    super.key,
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4.0),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13.0,
              ),
        ),
      ],
    );
  }
}
