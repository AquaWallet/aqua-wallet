import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/utils/utils.dart';

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
      return const SizedBox(height: 110.0);
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
            horizontal: context.adaptiveDouble(mobile: 16.0, smallMobile: 10.0),
            vertical: context.adaptiveDouble(mobile: 16.0, smallMobile: 10.0),
          ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
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
              fontSize: fontSize ?? 12.0,
              height: 1,
            ),
      ),
    );
  }
}
