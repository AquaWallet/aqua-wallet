import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveAssetBottomNav extends HookConsumerWidget {
  const ReceiveAssetBottomNav({
    super.key,
    required this.asset,
    this.address,
  });

  final Asset asset;
  final String? address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showCopyBottomSheet = useCallback(() {
      final systemOverlayColor = ref.read(systemOverlayColorProvider(context));

      // Change system overlay color to match modal
      systemOverlayColor.modalColor(context.aquaColors);

      AquaBottomSheet.show(
        context,
        colors: context.aquaColors,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaText.subtitleSemiBold(text: context.loc.share),
              const SizedBox(height: 24),
              //ANCHOR - Share Address Button
              if (address?.isNotEmpty ?? false) ...{
                AquaListItem(
                  title: context.loc.receiveAssetScreenCopyAddressOptionShare,
                  onTap: () async {
                    await Share.share(address!);
                    if (context.mounted) {
                      context.pop();
                    }
                  },
                  iconTrailing: AquaIcon.chevronRight(
                    color: context.aquaColors.textSecondary,
                    size: 18,
                  ),
                  iconLeading: AquaIcon.qrIcon(
                    color: context.aquaColors.textSecondary,
                  ),
                )
              },
              //ANCHOR - Share QR Image Button
              AquaListItem(
                title: context.loc.receiveAssetScreenCopyAddressOptionImage,
                onTap: () async {
                  try {
                    await shareWidgetAsImage(AquaAssetQRCode.qrKey);
                  } catch (e) {
                    if (context.mounted) {
                      context.showErrorSnackbar(
                        '${context.loc.failedToShareQrImage}: $e',
                      );
                    }
                  } finally {
                    if (context.mounted) {
                      context.pop();
                    }
                  }
                },
                iconTrailing: AquaIcon.chevronRight(
                  color: context.aquaColors.textSecondary,
                  size: 18,
                ),
                iconLeading: AquaIcon.image(
                  color: context.aquaColors.textSecondary,
                ),
              )
            ],
          ),
        ),
      ).then((_) {
        // Restore original system overlay color when modal is dismissed
        systemOverlayColor.themeBased();
      });
    }, [address]);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const SizedBox(width: 12),
        //ANCHOR - Share Button
        Expanded(
          child: _IconButton(
            onTap: showCopyBottomSheet,
            title: context.loc.share,
            icon: AquaIcon.share(
              color: context.aquaColors.textSecondary,
            ),
          ),
        ),
        //ANCHOR - Copy Address Button
        Expanded(
          child: _IconButton(
            onTap: address?.isNotEmpty ?? false
                ? () async => await context.copyToClipboard(address!)
                : null,
            title: context.loc.copyAddress,
            icon: AquaIcon.copy(
              color: context.aquaColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final AquaIcon icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          color: Colors.transparent,
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              AquaText.caption2SemiBold(text: title),
            ],
          ),
        ),
      ),
    );
  }
}
