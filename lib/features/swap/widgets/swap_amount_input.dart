import 'package:aqua/common/widgets/amount_text_field.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SwapAmountInput extends HookConsumerWidget {
  const SwapAmountInput({
    super.key,
    this.focusNode,
    this.isEditable = true,
    required this.isReceive,
    required this.onChanged,
    required this.onAssetSelected,
  });

  final FocusNode? focusNode;
  final bool isEditable;
  final bool isReceive;
  final Function(String)? onChanged;
  final Function(Asset) onAssetSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final globalKey = useMemoized(() => GlobalKey());

    final value = ref.watch(swapLoadingIndicatorStateProvider);
    final readOnly = value == const SwapProgressState.connecting() ||
        value == const SwapProgressState.waiting();
    final amount = isReceive
        ? ref.watch(swapIncomingReceiveAmountProvider(context)).valueOrNull
        : ref.watch(sideswapInputStateProvider).deliverAmount;
    final selectedAsset = ref.watch(sideswapInputStateProvider
        .select((p) => isReceive ? p.receiveAsset : p.deliverAsset));
    final counterAsset = ref.watch(sideswapInputStateProvider
        .select((p) => isReceive ? p.deliverAsset : p.receiveAsset));

    return BoxShadowContainer(
      bordered: true,
      color: Theme.of(context).colors.addressFieldContainerBackgroundColor,
      borderRadius: BorderRadius.circular(12.r),
      child: Row(
        children: [
          Expanded(
            child: Skeleton.ignore(
              ignore: readOnly,
              child: Container(
                height: 62.h,
                padding: EdgeInsets.only(right: 24.w),
                child: Center(
                  child: AmountTextField(
                    key: globalKey,
                    controller: controller,
                    focusNode: focusNode,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: readOnly && amount == '0'
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onBackground,
                        ),
                    cursorColor: Theme.of(context).colorScheme.onBackground,
                    text: amount,
                    onChanged: onChanged,
                    readOnly: !isEditable || readOnly,
                    autofocus: false,
                    filled: false,
                    decoration: InputDecoration(
                      filled: false,
                      border: InputBorder.none,
                      hintText: '0',
                      hintStyle:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SwapAssetPickerButton(
            isReceive: isReceive,
            selectedAsset: selectedAsset,
            counterAsset: counterAsset,
            onAssetSelected: onAssetSelected,
          ),
        ],
      ),
    );
  }
}
