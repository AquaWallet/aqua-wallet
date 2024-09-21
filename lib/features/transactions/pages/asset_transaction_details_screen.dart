import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/send/widgets/custom_fee_input_sheet.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetTransactionDetailsScreen extends StatelessWidget {
  static const routeName = '/assetTransactionDetailsScreen';

  const AssetTransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as TransactionUiModel;

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.r,
        onActionButtonPressed: () => Navigator.of(context).pop(),
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
            Navigator.of(context).pop();
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
    final transactionProvider = useMemoized(
      () => assetTransactionDetailsProvider((context, txnUiModel)),
    );

    final transaction = ref.watch(transactionProvider);
    final insufficientBalance = ref.watch(insufficientBalanceProvider);

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

    ref.listen(transactionsProvider(txnUiModel.asset), (previous, next) {
      ref.invalidate(transactionProvider);
    });

    final showRbfSuccessSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        builder: (_) => const RbfSuccessSheet(),
      );
    }, []);

    final showCustomFeeInputSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        builder: (_) => CustomFeeInputSheet(
            title: context.loc.assetTransactionDetailsReplaceByFeeInputTitle,
            // original transaction fee (in sats per vb) + 1 sat
            minimum: (txnUiModel.transaction.feeRate! ~/ 1000) + 1,
            transactionVsize: txnUiModel.transaction.transactionVsize,
            onConfirm: () async {
              try {
                final newFeeRatePerVb =
                    Decimal.tryParse(ref.read(customFeeInputProvider)!)
                        ?.toBigInt()
                        .toInt();
                final tx = GdkNewTransaction(
                    previousTransaction: txnUiModel.transaction,
                    feeRate: (newFeeRatePerVb! * 1000).toInt());

                final txReply = await ref
                    .read(bitcoinProvider)
                    .createTransaction(transaction: tx, isRbfTx: true);
                if (txReply == null) {
                  throw GdkNetworkException('Failed to create GDK transaction');
                }

                final signedTx =
                    await ref.read(bitcoinProvider).signTransaction(txReply);
                if (signedTx == null) {
                  throw GdkNetworkException('Failed to sign GDK transaction');
                }

                await ref
                    .read(electrsProvider)
                    .broadcast(signedTx.transaction!, NetworkType.bitcoin);

                showRbfSuccessSheet();
              } on GdkNetworkInsufficientFunds {
                ref.read(insufficientBalanceProvider.notifier).state =
                    InsufficientFundsType.fee;
                rethrow;
              } catch (e) {
                logger.d('[RBF] create TX error: $e');
                rethrow;
              }
            }),
      );
    }, []);

    // show a modal telling the user they don't have enough funds
    useEffect(() {
      if (insufficientBalance != null) {
        Future.microtask(() => showModalBottomSheet(
              context: context,
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: context.adaptiveDouble(
                  mobile: 0.4.sh,
                  tablet: 0.2.sh,
                ),
              ),
              builder: (_) => const InsufficientBalanceSheet(),
            ));
      }
      return null;
    }, [insufficientBalance]);

    return transaction.when(
      data: (detailsUiModel) => _TransactionDetailsContent(
        txnUiModel: txnUiModel,
        detailsUiModel: detailsUiModel,
        onRbfButtonPress: showCustomFeeInputSheet,
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
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }
}

class _TransactionDetailsContent extends HookWidget {
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
  Widget build(BuildContext context) {
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));

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
        height: 40.h,
        refreshingText: '',
        releaseText: '',
        completeText: '',
        failedText: '',
        idleText: '',
        idleIcon: null,
        failedIcon: null,
        releaseIcon: null,
        completeIcon: SizedBox.square(
          dimension: 28.r,
          child: CircularProgressIndicator(
            strokeWidth: 2.w,
          ),
        ),
        outerBuilder: (child) => Container(child: child),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            //ANCHOR - Transaction Type
            Text(
              detailsUiModel.type(context),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20.h),

            if ((detailsUiModel.dbTransaction?.type.isBoltzSwap ?? false)) ...[
              //ANCHOR - Boltz Swap Transaction Details
              BoltzSwapDetailsCard(uiModel: detailsUiModel),
              //ANCHOR - Boltz Reverse Transaction Details
              BoltzReverseSwapDetailsCard(uiModel: detailsUiModel),
              SizedBox(height: 20.h),
            ],
            //ANCHOR - General Transaction Details
            BoxShadowCard(
              color: Theme.of(context).colors.altScreenSurface,
              bordered: true,
              borderColor: Theme.of(context).colors.cardOutlineColor,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
                        SizedBox(height: 18.h),
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
                          SizedBox(height: 18.h),
                        ],
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionsNetworkFees,
                          value: '${item.feeAmount} ${item.feeAssetTicker}',
                        ),
                      ],
                      send: (item) => [
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionsTotalAmount,
                          value:
                              '${item.deliverAmount} ${item.deliverAssetTicker}',
                        ),
                        SizedBox(height: 18.h),
                        TransactionDetailsDataItem(
                          title: context.loc.assetTransactionsNetworkFees,
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
                    SizedBox(height: 18.h),
                    TransactionDetailsDataItem(
                      title: context.loc.assetTransactionsDate,
                      value: detailsUiModel.date,
                    ),
                    SizedBox(height: 18.h),
                    LabelCopyableTextView(
                      label: context.loc.assetTransactionDetailsTransactionId,
                      value: detailsUiModel.transactionId,
                    ),
                    SizedBox(height: 18.h),
                    ...detailsUiModel.maybeMap(
                      swap: (model) {
                        if (model.dbTransaction?.serviceAddress?.isNotEmpty ==
                            true) {
                          return [
                            LabelCopyableTextView(
                              label: context
                                  .loc.assetTransactionDetailsDepositAddress,
                              value: model.dbTransaction!.serviceAddress!,
                            ),
                          ];
                        }
                        return [];
                      },
                      orElse: () => [],
                    ),
                    SizedBox(height: 18.h),
                    // temp: don't show the liquid tx status if boltz - it's confusing.
                    // will be changed in redesign soon
                    if (!(detailsUiModel.dbTransaction?.type.isBoltzSwap ??
                        false)) ...[
                      Center(
                        child: TransactionDetailsStatusChip(
                          color: detailsUiModel.isPending
                              ? AquaColors.gray
                              : AquaColors.aquaGreen,
                          text: !detailsUiModel.isPending
                              ? context.loc.assetTransactionDetailsConfirmed
                              : detailsUiModel.isDeliverLiquid
                                  ? context.loc.assetTransactionDetailsAccepted
                                  : context.loc.assetTransactionDetailsPending,
                        ),
                      ),
                      SizedBox(height: 18.h),
                    ],
                    // Increase fee button
                    ...txnUiModel.maybeMap(
                      normal: (model) => (model.transaction.canRbf == true)
                          ? [
                              SizedBox(height: 12.h),
                              Center(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                    visualDensity: VisualDensity.compact,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    side: BorderSide(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .errorContainer,
                                      width: 1.r,
                                    ),
                                    textStyle: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontSize: 12.sp,
                                        ),
                                  ),
                                  onPressed: onRbfButtonPress,
                                  child: Text(context.loc
                                      .assetTransactionDetailsReplaceByFeeButton),
                                ),
                              ),
                            ]
                          : [],
                      orElse: () => [],
                    ),
                    SizedBox(height: 18.h),
                    Center(
                      child: TransactionDetailsExplorerButtons(
                        model: txnUiModel,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
            //ANCHOR - Peg Transaction Details
            SideswapPegDetailsCard(uiModel: detailsUiModel),
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
        SizedBox(height: 4.h),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13.sp,
              ),
        ),
      ],
    );
  }
}
