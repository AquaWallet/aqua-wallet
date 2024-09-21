import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/features/shared/shared.dart';
import 'package:lottie/lottie.dart';

class TransactionProcessingAnimation extends HookConsumerWidget {
  const TransactionProcessingAnimation({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Lottie.asset(
              animation.transactionProcessing,
              repeat: true,
              frameRate: const FrameRate(120),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
