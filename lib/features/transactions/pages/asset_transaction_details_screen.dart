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
import 'package:lottie/lottie.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';
import 'package:aqua/config/constants/animations.dart' as animation;

class AssetTransactionDetailsScreen extends HookConsumerWidget {
  static const routeName = '/assetTransactionDetailsScreen';

  const AssetTransactionDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as TransactionUiModel;
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));
    final transactionProvider =
        useMemoized(() => assetTransactionDetailsProvider((
              arguments.asset,
              arguments.transaction,
              context,
              arguments.dbTransaction,
            )));

    final transaction = ref.watch(transactionProvider);
    final insufficientBalance = ref.watch(insufficientBalanceProvider);

    useEffect(() {
      final subscription = ref
          .read(arguments.asset.isBTC ? bitcoinProvider : liquidProvider)
          .blockHeightEventSubject
          .stream
          .listen((lastBlock) {
        ref.read(transactionProvider.notifier).refresh();
      });

      return subscription.cancel;
    }, []);

    ref.listen(transactionsProvider(arguments.asset), (previous, next) {
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
            minimum: (arguments.transaction.feeRate! ~/ 1000) + 1,
            transactionVsize: arguments.transaction.transactionVsize,
            onConfirm: () async {
              try {
                final newFeeRatePerVb =
                    Decimal.tryParse(ref.read(customFeeInputProvider)!)
                        ?.toBigInt()
                        .toInt();
                final tx = GdkNewTransaction(
                    previousTransaction: arguments.transaction,
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
        child: transaction.when(
          data: (uiModel) => SmartRefresher(
            enablePullDown: true,
            key: refresherKey,
            controller: controller,
            physics: const BouncingScrollPhysics(),
            onRefresh: () async {
              ref.read(transactionProvider.notifier).refresh();
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
                    uiModel.type(context),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  SizedBox(height: 20.h),

                  if ((uiModel.dbTransaction?.type.isBoltzSwap ?? false)) ...[
                    //ANCHOR - Boltz Swap Transaction Details
                    BoltzSwapDetailsCard(uiModel: uiModel),
                    //ANCHOR - Boltz Reverse Transaction Details
                    BoltzReverseSwapDetailsCard(uiModel: uiModel),
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
                      padding: EdgeInsets.symmetric(
                          horizontal: 20.w, vertical: 20.h),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...uiModel.map(
                            swap: (item) => [
                              TransactionDetailsDataItem(
                                title: context
                                    .loc.assetTransactionDetailsDelivered,
                                value:
                                    '${item.deliverAmount} ${item.deliverAssetTicker}',
                              ),
                              SizedBox(height: 18.h),
                              TransactionDetailsDataItem(
                                title:
                                    context.loc.assetTransactionDetailsReceived,
                                value:
                                    '${item.receiveAmount} ${item.receiveAssetTicker}',
                              ),
                            ],
                            redeposit: (item) => [
                              if (!item.isConfidential) ...[
                                TransactionDetailsDataItem(
                                  title:
                                      context.loc.assetTransactionsTotalAmount,
                                  value:
                                      '${item.deliverAmount} ${item.deliverAssetTicker}',
                                ),
                                SizedBox(height: 18.h),
                              ],
                              TransactionDetailsDataItem(
                                title: context.loc.assetTransactionsNetworkFees,
                                value:
                                    '${item.feeAmount} ${item.feeAssetTicker}',
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
                                value:
                                    '${item.feeAmount} ${item.feeAssetTicker}',
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
                            value: uiModel.date,
                          ),
                          SizedBox(height: 18.h),
                          LabelCopyableTextView(
                            label: context
                                .loc.assetTransactionDetailsTransactionId,
                            value: uiModel.transactionId,
                          ),
                          SizedBox(height: 18.h),
                          ...uiModel.maybeMap(
                            swap: (model) {
                              if (model.dbTransaction?.serviceAddress
                                      ?.isNotEmpty ==
                                  true) {
                                return [
                                  LabelCopyableTextView(
                                    label: context.loc
                                        .assetTransactionDetailsDepositAddress,
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
                          if (!(uiModel.dbTransaction?.type.isBoltzSwap ??
                              false)) ...[
                            Center(
                              child: TransactionDetailsStatusChip(
                                color: uiModel.isPending
                                    ? AquaColors.gray
                                    : AquaColors.aquaGreen,
                                text: !uiModel.isPending
                                    ? context
                                        .loc.assetTransactionDetailsConfirmed
                                    : uiModel.isDeliverLiquid
                                        ? context
                                            .loc.assetTransactionDetailsAccepted
                                        : context
                                            .loc.assetTransactionDetailsPending,
                              ),
                            ),
                            SizedBox(height: 18.h),
                          ],
                          // Increase fee button
                          if (arguments.transaction.canRbf == true) ...[
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
                                onPressed: showCustomFeeInputSheet,
                                child: Text(context.loc
                                    .assetTransactionDetailsReplaceByFeeButton),
                              ),
                            ),
                          ],
                          SizedBox(height: 18.h),
                          Center(
                            child: TransactionDetailsExplorerButtons(
                              model: arguments,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  //ANCHOR - Peg Transaction Details
                  SideswapPegDetailsCard(uiModel: uiModel),
                ],
              ),
            ),
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

class RbfSuccessSheet extends HookConsumerWidget {
  const RbfSuccessSheet({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 21.h),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              SizedBox(height: 42.h),
              //ANCHOR - Illustration
              Lottie.asset(
                animation.tick,
                repeat: false,
                width: 100.r,
                height: 100.r,
                fit: BoxFit.cover,
              ),
              SizedBox(height: 42.h),
              //ANCHOR - Title
              Text(
                context.loc.assetTransactionDetailsReplaceByFeeSuccessMessage,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontSize: 16.sp,
                    ),
              ),
              SizedBox(height: 42.h),
            ],
          ),
        ));
  }
}
