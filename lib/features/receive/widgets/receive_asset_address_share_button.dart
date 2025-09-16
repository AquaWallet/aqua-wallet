import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/receive/keys/receive_screen_keys.dart';
import 'package:coin_cz/features/shared/shared.dart';
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
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return SizedBox(
      height: 48.0,
      width: isExpanded ? double.maxFinite : 52.0,
      child: OutlinedButton(
        key: ReceiveAssetKeys.receiveAssetShareAddressButton,
        onPressed: isEnabled ? () => Share.share(address) : null,
        style: OutlinedButton.styleFrom(
          backgroundColor:
              Theme.of(context).colors.addressFieldContainerBackgroundColor,
          foregroundColor: Theme.of(context).colors.onBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          side: !darkMode
              ? BorderSide(
                  color: Theme.of(context).colors.roundedButtonOutlineColor,
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              Svgs.share,
              width: 17.0,
              height: 17.0,
              colorFilter: ColorFilter.mode(
                isEnabled
                    ? Theme.of(context).colors.onBackground
                    : Theme.of(context).colorScheme.onSurface,
                BlendMode.srcIn,
              ),
            ),
            if (isExpanded) ...[
              const SizedBox(width: 10.0),
              Text(
                AppLocalizations.of(context)!.receiveAssetScreenShare,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isEnabled
                          ? Theme.of(context).colors.onBackground
                          : Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
