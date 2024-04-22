import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetTransactionDetailsScreen extends HookConsumerWidget {
  static const routeName = '/assetTransactionDetailsScreen';

  const AssetTransactionDetailsScreen({Key? key}) : super(key: key);

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
                  //ANCHOR - General Transaction Details
                  GeneralTransactionDetailsCard(uiModel: uiModel),
                  SizedBox(height: 20.h),
                  //ANCHOR - Peg Transaction Details
                  SideswapPegDetailsCard(uiModel: uiModel),
                  //ANCHOR - Boltz Swap Transaction Details
                  BoltzSwapDetailsCard(uiModel: uiModel),
                  //ANCHOR - Boltz Reverse Transaction Details
                  BoltzReverseSwapDetailsCard(uiModel: uiModel),
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
