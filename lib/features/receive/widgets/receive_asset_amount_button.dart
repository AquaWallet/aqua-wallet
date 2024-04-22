import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class ReceiveAssetAmountButton extends HookConsumerWidget {
  const ReceiveAssetAmountButton({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    final showAmountBottomSheet = useCallback(() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        // disallow dismiss for lightning - use must enter an amount or cancel
        isDismissible: !asset.isLightning,
        backgroundColor: Theme.of(context).colorScheme.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30.r),
            topRight: Radius.circular(30.r),
          ),
        ),
        builder: (_) => ReceiveAmountInputSheet(
          asset: asset,
          onCancel: () => Navigator.of(context).pop(),
        ),
      );
    }, [asset]);

    return OutlinedButton(
      onPressed: showAmountBottomSheet,
      style: OutlinedButton.styleFrom(
        backgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        side: !darkMode
            ? BorderSide(
                color: Theme.of(context).colors.roundedButtonOutlineColor,
                width: 1.w,
              )
            : null,
      ),
      child: Row(
        children: [
          SvgPicture.asset(
            Svgs.setAmount,
            width: 16.r,
            height: 16.r,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 25.w),
          Text(
            AppLocalizations.of(context)!.receiveAssetScreenSetAmount,
          ),
        ],
      ),
    );
  }
}
