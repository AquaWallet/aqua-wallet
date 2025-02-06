import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:lottie/lottie.dart';

class RbfSuccessSheet extends HookConsumerWidget {
  const RbfSuccessSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 21.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          children: [
            const SizedBox(height: 42.0),
            //ANCHOR - Illustration
            Lottie.asset(
              animation.tick,
              repeat: false,
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 42.0),
            //ANCHOR - Title
            Text(
              context.loc.assetTransactionDetailsReplaceByFeeSuccessMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 16.0,
                  ),
            ),
            const SizedBox(height: 42.0),
          ],
        ),
      ),
    );
  }
}
