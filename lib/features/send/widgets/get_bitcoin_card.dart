import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

const iconsForUnit = {
  FeeAsset.lbtc: Svgs.liquidAsset,
  FeeAsset.tetherUsdt: Svgs.usdtAsset,
  FeeAsset.btc: Svgs.btcAsset,
};

const labelForUnit = {
  FeeAsset.lbtc: 'Liquid',
  FeeAsset.tetherUsdt: 'USDt',
  FeeAsset.btc: 'Bitcoin',
};

class GetBitcoinCard extends ConsumerWidget {
  const GetBitcoinCard({
    super.key,
    required this.feeAsset,
    required this.onTap,
  });

  final FeeAsset feeAsset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.0),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Row(
              children: [
                const SizedBox(width: 14.0),
                SvgPicture.asset(
                  iconsForUnit[feeAsset]!,
                  width: 38.0,
                  height: 38.0,
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.loc.insufficientFundsSheetAssetTitle(
                            labelForUnit[feeAsset]!),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontSize: 18.0,
                                ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        context.loc.insufficientFundsSheetAssetDescription,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontSize: 12.0,
                                ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40.0,
                  height: 40.0,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).isLight
                          ? Theme.of(context).colors.divider
                          : Colors.transparent,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                    color: Theme.of(context).colors.background,
                  ),
                  child: SvgPicture.asset(
                    Svgs.arrowForward,
                    width: 14.0,
                    height: 14.0,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).colors.onBackground, BlendMode.srcIn),
                    fit: BoxFit.scaleDown,
                  ),
                ),
                const SizedBox(width: 18.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
