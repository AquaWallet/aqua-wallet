import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';

class WalletInternalSwapButton extends StatelessWidget {
  const WalletInternalSwapButton({
    super.key,
    this.isLoading = false,
  });

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 33.0,
      child: OutlinedButton(
        onPressed: !isLoading ? () => context.push(SwapScreen.routeName) : null,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 9.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          side: BorderSide(
            color: context.colors.swapButtonForeground,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min, // Let the Row take up only the space needed
          children: [
            const SizedBox(width: 1.0),
            UiAssets.svgs.assetHeaderSwap.svg(
              width: 10.0,
              fit: BoxFit.contain,
              colorFilter: ColorFilter.mode(
                context.colors.swapButtonForeground,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 9.0),
            Text(
              context.loc.swap,
              style: TextStyle(
                fontSize: 14.0,
                letterSpacing: 0,
                fontWeight: FontWeight.w700,
                color: context.colors.swapButtonForeground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
