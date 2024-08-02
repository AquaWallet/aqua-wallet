import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/features/shared/shared.dart';
import 'package:lottie/lottie.dart';

class TransactionProcessingAnimation extends HookConsumerWidget {
  const TransactionProcessingAnimation({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context, ref) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Lottie.asset(
                animation.transactionProcessing,
                repeat: true,
                width: 132.r,
                height: 132.r,
                frameRate: const FrameRate(120),
                fit: BoxFit.contain,
              ),
              SizedBox(height: 26.h),
              Text(
                message,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20.sp,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
