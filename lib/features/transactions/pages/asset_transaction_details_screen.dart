import 'package:aqua/features/rbf/rbf.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide ResponsiveEx;

typedef OnExplorerTap = void Function(
  String transactionId, {
  required bool isBtc,
});
typedef OnBlindingUrlTap = void Function(String blindingUrl);

class AssetTransactionDetailsScreen extends HookConsumerWidget {
  static const routeName = '/assetTransactionDetailsScreen';

  const AssetTransactionDetailsScreen({
    super.key,
    required this.args,
  });

  final TransactionDetailsArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionProvider = assetTransactionDetailsProvider(args);
    final uiModel = ref.watch(transactionProvider).valueOrNull;

    if (uiModel == null) {
      //TODO: Fix transaction details momentarily crashes due to RBF txn delay
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AquaTopAppBar(
          colors: context.aquaColors,
        ),
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
            ),
          ),
        ),
      );
    }

    final onExplorerTap = useCallback((
      String transactionId, {
      required bool isBtc,
    }) {
      final exp = ref.read(blockExplorerProvider).currentBlockExplorer;
      final url = isBtc ? exp.btcUrl : exp.liquidUrl;
      final link = '$url$transactionId';
      ref.read(urlLauncherProvider).open(link);
    }, []);
    final onBlindingUrlTap = useCallback((String blindingUrl) {
      final exp = ref.read(blockExplorerProvider).currentBlockExplorer;
      final link = '${exp.liquidUrl}$blindingUrl';
      ref.read(urlLauncherProvider).open(link);
    }, []);

    useEffect(() {
      final isLightningSend =
          uiModel.mapOrNull(send: (t) => t.isLightning) ?? false;
      final isFailed = uiModel.mapOrNull(send: (t) => t.isFailed) ?? false;

      if (context.mounted && isLightningSend && isFailed) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AquaTooltip.show(
            context,
            message: context.loc.failedLightningTransactionTooltip,
            colors: context.aquaColors,
          );
        });
      }
      return null;
    }, [context, uiModel]);

    final transactionFromStorage = ref
        .watch(transactionStorageProvider)
        .valueOrNull
        ?.firstWhereOrNull((tx) => tx.txhash == args.transactionId);

    return uiModel.map(
      send: (model) => AssetSendTransactionDetails(
        model.copyWith(dbTransaction: transactionFromStorage),
        onExplorerTap: onExplorerTap,
        onBlindingUrlTap: onBlindingUrlTap,
        onRbfTap: (txnId) =>
            context.push(RbfFeeInputScreen.routeName, extra: txnId),
        onOpenUrl: ref.read(urlLauncherProvider).open,
      ),
      receive: (model) => AssetReceiveTransactionDetails(
        model.copyWith(dbTransaction: transactionFromStorage),
        onExplorerTap: onExplorerTap,
        onBlindingUrlTap: onBlindingUrlTap,
        onOpenUrl: ref.read(urlLauncherProvider).open,
      ),
      swap: (model) => AssetSwapTransactionDetails(
        model.copyWith(dbTransaction: transactionFromStorage),
        onExplorerTap: onExplorerTap,
        onBlindingUrlTap: onBlindingUrlTap,
      ),
      peg: (model) => AssetPegTransactionDetails(
        model.copyWith(dbTransaction: transactionFromStorage),
        onExplorerTap: onExplorerTap,
        onBlindingUrlTap: onBlindingUrlTap,
      ),
      redeposit: (model) => AssetRedepositTransactionDetails(
        model.copyWith(dbTransaction: transactionFromStorage),
        onExplorerTap: onExplorerTap,
        onBlindingUrlTap: onBlindingUrlTap,
      ),
    );
  }
}
