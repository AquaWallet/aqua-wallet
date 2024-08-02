import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';

class PegInfoMessageView extends HookConsumerWidget {
  const PegInfoMessageView({
    super.key,
    this.fontSize,
    this.padding,
  });

  final double? fontSize;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sideswapInputStateProvider);

    if (!input.isPeg) {
      return const SizedBox.shrink();
    }

    return PegInfoMessage(
      padding: padding,
      isPegIn: input.isPegIn,
      fontSize: fontSize,
    );
  }
}

class PegInfoMessage extends StatelessWidget {
  const PegInfoMessage({
    super.key,
    required this.isPegIn,
    this.padding,
    this.fontSize,
  });

  final bool isPegIn;
  final EdgeInsets? padding;
  final double? fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ??
          EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 16.h,
          ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      child: Text(
        isPegIn
            ? context.loc.swapPanelPegInInfo
            : context.loc.swapPanelPegOutInfo,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: fontSize ?? 12.sp,
              height: 1,
            ),
      ),
    );
  }
}
