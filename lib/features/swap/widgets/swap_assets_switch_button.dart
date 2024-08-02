import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SwapAssetsSwitchButton extends ConsumerWidget {
  const SwapAssetsSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(100),
      borderOnForeground: true,
      color: Theme.of(context).colorScheme.background,
      child: InkWell(
        onTap: () =>
            ref.read(sideswapInputStateProvider.notifier).switchAssets(),
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: SvgPicture.asset(
            Svgs.exchangeSwap,
            width: 20.r,
            height: 20.r,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
