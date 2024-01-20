import 'package:aqua/config/config.dart';
import 'package:aqua/features/external/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetTransactionDetailsScreen extends HookConsumerWidget {
  static const routeName = '/assetTransactionDetailsScreen';

  const AssetTransactionDetailsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as TransactionUiModel;
    final tuple = (arguments.asset, arguments.transaction, context);
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));
    final transactionProvider =
        useMemoized(() => assetTransactionDetailsProvider(tuple));

    final transaction = ref.watch(transactionProvider);

    useEffect(() {
      final subscription = Stream.periodic(const Duration(seconds: 10))
          .listen((_) => ref.read(transactionProvider.notifier).refresh());
      return subscription.cancel;
    });

    ref.listen(transactionsProvider(arguments.asset), (previous, next) {
      ref.invalidate(transactionProvider);
    });

    final boltzSwapData = ref
        .watch(boltzSwapFromTxHashProvider(arguments.transaction.txhash ?? ''))
        .asData
        ?.value;

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
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 31.h, horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...uiModel.items.map(
                    (itemUiModel) => itemUiModel.map(
                      header: (item) =>
                          TransactionDetailsHeaderItem(uiModel: item),
                      data: (item) => TransactionDetailsDataItem(uiModel: item),
                      notes: (_) => const SizedBox.shrink(),
                      divider: (_) => Container(
                        margin: EdgeInsets.symmetric(vertical: 20.h),
                        child: DashedDivider(
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      copyableData: (item) =>
                          TransactionDetailsCopyableItem(uiModel: item),
                    ),
                  ),

                  SizedBox(height: 32.h),

                  //ANCHOR - Copyable Boltz Id
                  if (boltzSwapData?.response.id != null) ...[
                    TransactionDetailsCopyableItem(
                      uiModel: AssetTransactionDetailsCopyableItemUiModel(
                        title: AppLocalizations.of(context)!
                            .sendAssetCompleteScreenBoltzIdLabel,
                        value: boltzSwapData?.response.id ?? '',
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ],

                  TransactionDetailsExplorerButtons(model: arguments),
                ],
              ),
            ),
          ),
          // TransactionDetailsExplorerButtons(model: arguments),
          loading: () => Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ),
          error: (_, __) => Center(
            child: GenericErrorWidget(
              buttonTitle: AppLocalizations.of(context)!
                  .assetTransactionDetailsErrorButton,
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
