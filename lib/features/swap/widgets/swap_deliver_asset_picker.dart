import 'package:aqua/features/swap/swap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SwapDeliverAssetPicker extends ConsumerWidget {
  const SwapDeliverAssetPicker({
    Key? key,
    this.focusNode,
  }) : super(key: key);

  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //ANCHOR - Title
            Text(
              AppLocalizations.of(context)!.exchangeSwapTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            //ANCHOR - Send All Button
            TextButton(
              onPressed: () => ref
                  .read(sideswapInputStateProvider.notifier)
                  .setMaxDeliverAmount(),
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.titleSmall,
                foregroundColor: Theme.of(context).colorScheme.onBackground,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6.r),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2.r,
                  ),
                ),
              ),
              child: Text(
                AppLocalizations.of(context)!.swapScreenConvertAllButton,
              ),
            )
          ],
        ),
        SizedBox(height: 13.h),
        //ANCHOR - Deliver Asset Picker
        SwapAmountInput(
          isReceive: false,
          focusNode: focusNode,
          onChanged: (value) => ref
              .read(sideswapInputStateProvider.notifier)
              .setDeliverAmount(value),
          onAssetSelected: (asset) => ref
              .read(sideswapInputStateProvider.notifier)
              .setDeliverAsset(asset),
        ),
        SizedBox(height: 14.h),
        //ANCHOR - Balance
        const SwapAssetBalance(isReceive: false),
      ],
    );
  }
}
