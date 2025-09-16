import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SwapAssetsSwitchButton extends ConsumerWidget {
  const SwapAssetsSwitchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(100),
      borderOnForeground: true,
      color: Theme.of(context).colors.background,
      child: InkWell(
        onTap: () =>
            ref.read(sideswapInputStateProvider.notifier).switchAssets(),
        borderRadius: BorderRadius.circular(100),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            Svgs.exchangeSwap,
            width: 20.0,
            height: 20.0,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colors.onBackground,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
