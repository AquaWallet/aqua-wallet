import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapProcessingIndicator extends HookConsumerWidget {
  const SwapProcessingIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.read(swapIncomingDeliverAmountProvider);
    final inputState = ref.read(sideswapInputStateProvider);
    final deliverAssetTicker = inputState.deliverAsset?.ticker ?? '';
    final receiveAssetTicker = inputState.receiveAsset?.ticker ?? '';

    return TransactionProcessingAnimation(
      message: AppLocalizations.of(context)!.swapScreenLoadingMessage(
        amount,
        deliverAssetTicker,
        receiveAssetTicker,
      ),
    );
  }
}
