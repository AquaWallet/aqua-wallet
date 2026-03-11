import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/rbf/rbf.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/main.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final _logger = CustomLogger(FeatureFlag.transactions);

class RbfFeeInputScreen extends HookConsumerWidget {
  const RbfFeeInputScreen({
    super.key,
    required this.transactionId,
  });

  final String transactionId;

  static const routeName = '/rbfFeeInput';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final textUpdates = useListenable(controller);
    final customRateSatsPerVByte = useMemoized(
      () => int.tryParse(controller.text) ?? 0,
      [textUpdates.text],
    );

    final provider = useMemoized(
      () => bitcoinRbfInputStateProvider(transactionId),
      [transactionId],
    );
    final input = ref.watch(provider).valueOrNull;
    final feeRate = input?.feeRate.toDouble();
    final feeInFiat = input?.feeInFiat;

    final minFeeRate = input?.minFeeRate ?? 0;
    final isBelowMinimum = useMemoized(
      () => minFeeRate > customRateSatsPerVByte,
      [minFeeRate, customRateSatsPerVByte],
    );
    final isError = useMemoized(
      () => textUpdates.text.isNotEmpty && isBelowMinimum,
      [isBelowMinimum, textUpdates.text],
    );

    //ANCHOR - Invalidate RBF provider when app is brought back to foreground
    final wasInBackground = usePrevious(ref.watch(isAppInBackground));
    final isInBackground = ref.watch(isAppInBackground);

    useEffect(() {
      if (wasInBackground == null) return;
      if (wasInBackground && !isInBackground) {
        ref.invalidate(bitcoinRbfProvider(transactionId));
      }
      return null;
    }, [isInBackground, wasInBackground]);

    //ANCHOR - Update fee rate
    useEffect(() {
      ref.read(provider.notifier).updateFeeRate(controller.text);
      return null;
    }, [controller.text]);

    //ANCHOR - RBF Success Callback
    final onRbfSuccess = useCallback((String txnHash) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AquaModalSheet.show(
          context,
          copiedToClipboardText: context.loc.copiedToClipboard,
          icon: AquaIcon.checkCircle(color: Colors.white),
          iconVariant: AquaRingedIconVariant.info,
          title: context.loc.feeIncreased,
          message: context.loc.transactionFeeRateHasBeenIncreased,
          primaryButtonText: context.loc.commonGotIt,
          onPrimaryButtonTap: () => context.popUntilPath(HomeScreen.routeName),
          secondaryButtonText: context.loc.commonSwapViewReceipt,
          onSecondaryButtonTap: () => context
            ..popUntilPath(AssetTransactionsScreen.routeName)
            ..push(AssetTransactionDetailsScreen.routeName,
                extra: TransactionDetailsArgs(
                  asset: Asset.btc(),
                  transactionId: txnHash,
                )),
          colors: context.aquaColors,
        );
      });
    }, [transactionId]);

    //ANCHOR - Insufficient Funds Callback
    final onInsufficientFunds = useCallback(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AquaModalSheet.show(
          context,
          copiedToClipboardText: context.loc.copiedToClipboard,
          icon: AquaIcon.warning(color: Colors.white),
          iconVariant: AquaRingedIconVariant.danger,
          title: context.loc.insufficientFunds,
          message: context.loc.insufficientFundsSheetMessage,
          primaryButtonText: context.loc.ok,
          onPrimaryButtonTap: () => context.pop(),
          colors: context.aquaColors,
        );
      });
    }, []);

    //ANCHOR - RBF Failure Callback
    final onRbfFailed = useCallback(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AquaModalSheet.show(
          context,
          copiedToClipboardText: context.loc.copiedToClipboard,
          title: context.loc.feeIncreaseFailed,
          message: context.loc.feeIncreaseFailedMessage,
          primaryButtonText: context.loc.commonGotIt,
          onPrimaryButtonTap: () =>
              context.popUntilPath(AssetTransactionsScreen.routeName),
          colors: context.aquaColors,
        );
      });
    }, []);

    //ANCHOR - Listen to RBF provider to show RBF Success or Insufficient Funds Modal Sheet
    ref.listen(bitcoinRbfProvider(transactionId), (prev, next) {
      if (next.error is GdkNetworkUnhandledException) {
        onRbfFailed();
        return;
      }
      if (next.error is GdkNetworkInsufficientFunds ||
          next.error is GdkNetworkInsufficientFundsForFee) {
        onInsufficientFunds();
        return;
      }
      final txnHash = next.valueOrNull;
      if (txnHash != null && txnHash != prev?.valueOrNull) {
        _logger.debug('[RBF] Replacing transaction with hash: $txnHash');
        onRbfSuccess(txnHash);
      }
    });

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.increaseFee,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    //ANCHOR - Amount Input Field
                    IntrinsicWidth(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 120,
                          maxWidth: double.infinity,
                        ),
                        child: TextField(
                          controller: controller,
                          style: AquaTypography.h3SemiBold,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            filled: false,
                            fillColor: Colors.transparent,
                            hintText: '0',
                            hintStyle: AquaTypography.h3SemiBold,
                            isCollapsed: true,
                            isDense: true,
                            suffixIcon: AquaText.h3SemiBold(
                              text: context.loc.satsPerVByteWithoutApprox(''),
                              color: context.aquaColors.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    //ANCHOR - Fiat Fee
                    AquaText.body1Medium(
                      text: '~ $feeInFiat',
                      color: context.aquaColors.textSecondary,
                    ),
                  ],
                ),
              ),
              //ANCHOR - Minimum Fee
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AquaText.body2SemiBold(
                    text: context.loc.min,
                    color: isError
                        ? context.aquaColors.accentDanger
                        : context.aquaColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  AquaText.body2SemiBold(
                    text: context.loc.satsPerVByteWithoutApprox(minFeeRate),
                    color: isError
                        ? context.aquaColors.accentDanger
                        : context.aquaColors.textPrimary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              //ANCHOR - Numpad
              AquaNumpad(
                decimalAllowed: false,
                onKeyPressed: controller.addKey,
                colors: context.aquaColors,
              ),
              const SizedBox(height: 16),
              //ANCHOR - Confirm Button
              AquaSlider(
                width: MediaQuery.sizeOf(context).width,
                text: context.loc.confirm,
                enabled: !isBelowMinimum,
                onConfirm: () => ref
                    .read(bitcoinRbfProvider(transactionId).notifier)
                    .createRbfTransaction(feeRate!),
                colors: context.aquaColors,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
