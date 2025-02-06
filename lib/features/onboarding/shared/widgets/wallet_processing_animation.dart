import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:aqua/config/config.dart';

enum WalletProcessType {
  create,
  restore,
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
      return null;
    }, []);

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                animation.walletProcessing,
                repeat: true,
                width: 132.0,
                height: 132.0,
                frameRate: const FrameRate(120),
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 26.0),
              Text(
                type == WalletProcessType.create
                    ? context.loc.walletCreateAnimationTitle
                    : context.loc.walletRestoreAnimationTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20.0,
                      color: Theme.of(context).colors.onBackground,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
