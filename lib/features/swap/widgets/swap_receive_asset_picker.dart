import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

class SwapReceiveAssetPicker extends ConsumerWidget {
  const SwapReceiveAssetPicker({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Title
        Text(
          AppLocalizations.of(context)!.exchangeSwapForTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SizedBox(height: 9.h),
        //ANCHOR - Receive Asset Picker
        SwapAmountInput(
          isReceive: true,
          isEditable: false,
          onChanged: (value) => ref
              .read(sideswapInputStateProvider.notifier)
              .setReceiveAmount(value),
          onAssetSelected: (asset) => ref
              .read(sideswapInputStateProvider.notifier)
              .setReceiveAsset(asset),
        ),
        SizedBox(height: 14.h),
        //ANCHOR - Balance
        const SwapAssetBalance(isReceive: true),
      ],
    );
  }
}
