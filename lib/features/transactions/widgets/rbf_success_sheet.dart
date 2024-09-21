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
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 21.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          children: [
            SizedBox(height: 42.h),
            //ANCHOR - Illustration
            Lottie.asset(
              animation.tick,
              repeat: false,
              width: 100.r,
              height: 100.r,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 42.h),
            //ANCHOR - Title
            Text(
              context.loc.assetTransactionDetailsReplaceByFeeSuccessMessage,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontSize: 16.sp,
                  ),
            ),
            SizedBox(height: 42.h),
          ],
        ),
      ),
    );
  }
}
