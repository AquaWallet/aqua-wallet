import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/settings/settings.dart';

class BalanceVisibilityToggle extends ConsumerWidget {
  const BalanceVisibilityToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBalanceHidden =
        ref.watch(prefsProvider.select((p) => p.isBalanceHidden));

    return GestureDetector(
      onTap: () => ref.read(prefsProvider).switchBalanceHidden(),
      child: SvgPicture.asset(
        isBalanceHidden ? Svgs.eyeSlashIcon : Svgs.eyeIcon,
        fit: BoxFit.scaleDown,
        colorFilter: ColorFilter.mode(
          Theme.of(context).colors.headerUsdContainerTextColor,
          BlendMode.srcIn,
        ),
      ),
    );
  }
}
