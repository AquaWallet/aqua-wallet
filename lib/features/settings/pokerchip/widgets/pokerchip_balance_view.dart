import 'package:aqua/features/settings/pokerchip/pokerchip.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class PokerchipBalanceCard extends HookConsumerWidget {
  const PokerchipBalanceCard({
    super.key,
    required this.data,
  });

  final PokerchipBalanceState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        children: [
          //ANCHOR: Balance Title
          SizedBox(height: 31.h),
          Text(
            context.loc.pokerChipBalanceLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w400,
                ),
          ),
          SizedBox(height: 24.h),
          //ANCHOR - Asset Icon
          PokerchipAssetIcon(data.asset),
          SizedBox(height: 26.h),
          //ANCHOR: Balance value
          CopyableTextView(
            text: data.balance.toUpperCase(),
            iconSize: 14.r,
            textAlign: TextAlign.center,
            textStyle: Theme.of(context).textTheme.titleLarge,
            margin: EdgeInsetsDirectional.symmetric(horizontal: 40.w),
          ),
          SizedBox(height: 24.h),
          //ANCHOR - Address
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20.w),
            child: CopyableAddressView(address: data.address),
          ),
          SizedBox(height: 21.h),
        ],
      ),
    );
  }
}
