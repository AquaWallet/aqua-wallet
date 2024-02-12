import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';

class PegInfoMessage extends HookConsumerWidget {
  const PegInfoMessage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);

    if (!input.isPeg) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 30.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      child: Text(
        input.isPegIn
            ? AppLocalizations.of(context)!.swapPanelPegInInfo
            : AppLocalizations.of(context)!.swapPanelPegOutInfo,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 10.sp,
            ),
      ),
    );
  }
}
