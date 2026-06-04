import 'package:aqua/features/lightning_address/providers/providers.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

import 'gift_box_widget.dart';

class LnAddressGiftOpenedScreen extends HookConsumerWidget {
  static const routeName = '/lnAddressGiftOpenedScreen';

  const LnAddressGiftOpenedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registrationAsync = ref.watch(lnAddressRegistrationProvider);
    final address = ref.watch(lightningAddressProvider)?.address;
    final parts = address?.split('@');
    final username = parts?.firstOrNull ?? '';
    final domain = parts != null && parts.length > 1 ? '@${parts[1]}' : '';

    final addressController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    final addressOpacity = CurvedAnimation(
      parent: addressController,
      curve: Curves.easeIn,
    );
    final addressScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: addressController, curve: Curves.easeOutBack),
    );

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 900), () {
        if (addressController.isDismissed) addressController.forward();
      });
      return null;
    }, const []);

    return Theme(
      data: AquaLightTheme().themeData,
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: Stack(
          children: [
            const GiftDotsBackground(),
            SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: AquaGlassButton(
                        icon: AquaIcon.close(
                          color: AquaColors.lightColors.accentBrand,
                        ),
                        onTap: () => context.pop(),
                      ),
                    ),
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Hero(
                            tag: 'lnAddressGiftPresent',
                            child: GiftBoxWidget(animated: true),
                          ),
                          FadeTransition(
                            opacity: addressOpacity,
                            child: ScaleTransition(
                              scale: addressScale,
                              child: Wrap(
                                alignment: WrapAlignment.center,
                                children: [
                                  AquaText.h3SemiBold(
                                    text: username,
                                    color: Colors.white,
                                    maxLines: 2,
                                  ),
                                  AquaText.h3SemiBold(
                                    text: domain,
                                    color:
                                        AquaPrimitiveColors.palatinateBlue750,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AquaButton.tertiary(
                      isInverted: true,
                      text: context.loc.okay,
                      isLoading: registrationAsync.isLoading,
                      onPressed: registrationAsync.isLoading
                          ? null
                          : () {
                              ref
                                  .read(lnReceiveModeProvider.notifier)
                                  .setAddressMode();
                              context.pushReplacement(
                                ReceiveAssetScreen.routeName,
                                extra: ReceiveArguments.fromAsset(
                                    Asset.lightning()),
                              );
                            },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
