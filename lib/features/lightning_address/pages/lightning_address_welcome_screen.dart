import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/features/home/providers/home_provider.dart';
import 'package:aqua/features/lightning_address/pages/gift_box_widget.dart';
import 'package:aqua/features/lightning_address/pages/ln_address_gift_screen.dart';
import 'package:aqua/features/lightning_address/providers/lightning_address_notification_provider.dart';
import 'package:aqua/features/lightning_address/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LightningAddressWelcomeScreen extends HookConsumerWidget {
  const LightningAddressWelcomeScreen({super.key});

  static const routeName = '/lightningAddressWelcomeScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPrimaryButtonTap = useCallback(() {
      final router = ref.read(routerProvider);
      ref
          .read(lightningAddressNotificationProvider.notifier)
          .markWelcomeScreenAsSeen()
          .then((_) {
        ref.read(homeProvider).selectTab(WalletTabs.settings.index);
        if (router.canPop()) {
          router.pop();
        }
        router.push(LnAddressGiftScreen.routeName);
      });
    }, [ref]);

    onClose() {
      ref
          .read(lightningAddressNotificationProvider.notifier)
          .markWelcomeScreenAsSeen();
      context.pop();
    }

    return Theme(
      data: AquaLightTheme().themeData,
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    AquaGlassButton(
                      icon:
                          AquaIcon.close(color: context.aquaColors.accentBrand),
                      onTap: onClose,
                    ),
                  ],
                ),
                const Spacer(),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 220,
                    maxHeight: 220,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: const Stack(
                      fit: StackFit.expand,
                      children: [
                        Positioned.fill(
                          child: ColoredBox(
                            color: AquaPrimitiveColors.aquaBlue300,
                          ),
                        ),
                        Positioned.fill(
                            child: GiftDotsBackground(sparse: true)),
                        Center(
                          child: GiftBoxWidget(animated: false),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                YouAquaNetAddress(
                  youColor: AquaPrimitiveColors.white,
                  aquaNetColor: AquaColors.lightColors.link,
                  style: AquaTypography.h3SemiBold,
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 300,
                  ),
                  child: AquaText.body1(
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      color: AquaColors.lightColors.link,
                      text: context.loc.lightningAddressWelcomeSubtitle),
                ),
                const Spacer(),
                AquaButton.primary(
                  isInverted: true,
                  text: context.loc.lightningAddressWelcomeViewButton,
                  onPressed: onPrimaryButtonTap,
                ),
                const SizedBox(height: 16),
                AquaButton.tertiary(
                  isInverted: true,
                  text: context.loc.notNow,
                  onPressed: onClose,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
