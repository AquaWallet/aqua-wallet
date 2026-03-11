import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

enum WalletProcessType {
  create,
  switchWallet,
  deleteWallet,
}

class WalletProcessingAnimation extends HookConsumerWidget {
  const WalletProcessingAnimation({super.key, required this.type});

  final WalletProcessType type;

  @override
  Widget build(BuildContext context, ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(systemOverlayColorProvider(context)).forceLight();
      });
      return () {
        Future.microtask(() {
          ref.read(systemOverlayColorProvider(context)).themeBased();
        });
      };
    }, []);

    final animationTitle =
        useMemoized(() => _getAnimationTitle(context, type), [type]);

    final dots = useState('.');

    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        dots.value = dots.value == '...' ? '.' : '${dots.value}.';
      });
      return timer.cancel;
    }, []);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //ANCHOR - Logo
              AquaIcon.aquaLogo(
                size: 32,
                color: AquaPrimitiveColors.palatinateBlue750,
              ),
              const SizedBox(height: 24.0),
              //ANCHOR - Just a moment
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AquaText.h3SemiBold(
                      text: context.loc.commonJustAMoment,
                      color: AquaPrimitiveColors.palatinateBlue750),
                  SizedBox(
                    width: 30,
                    child: AquaText.h3SemiBold(
                      text: dots.value,
                      color: AquaPrimitiveColors.palatinateBlue750,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8.0),
              AquaText.body1Medium(
                  color: AquaPrimitiveColors.palatinateBlue750,
                  text: animationTitle,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  String _getAnimationTitle(BuildContext context, WalletProcessType type) {
    switch (type) {
      case WalletProcessType.create:
        return context.loc.walletProcessingCreateMessage;
      case WalletProcessType.switchWallet:
        return context.loc.walletSwitchAnimationTitle;
      case WalletProcessType.deleteWallet:
        return context.loc.walletDeleteAnimationTitle;
    }
  }
}
