import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';
import 'package:share_plus/share_plus.dart';

class ReceiveAssetAddressShareButton extends HookConsumerWidget {
  const ReceiveAssetAddressShareButton({
    super.key,
    required this.address,
    required this.isEnabled,
    required this.isExpanded,
  });

  final bool isEnabled;
  final bool isExpanded;
  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return SizedBox(
      height: 48.h,
      width: isExpanded ? double.maxFinite : 52.w,
      child: OutlinedButton(
        onPressed: isEnabled ? null : () => Share.share(address),
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
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              Svgs.share,
              width: 17.r,
              height: 17.r,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colorScheme.onBackground,
                BlendMode.srcIn,
              ),
            ),
            if (isExpanded) ...[
              SizedBox(width: 10.w),
              Text(
                AppLocalizations.of(context)!.receiveAssetScreenShare,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
