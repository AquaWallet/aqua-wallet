import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class WalletRestoreHeader extends StatelessWidget {
  const WalletRestoreHeader({
    super.key,
    required this.error,
  });

  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20.h),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.restoreInputTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24.sp,
                  letterSpacing: 1,
                ),
          ),
          SizedBox(height: 16.h),
          if (error) ...{
            Text(
              context.loc.restoreInputError,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          } else ...{
            Text(
              context.loc.restoreInputSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            )
          },
        ],
      ),
    );
  }
}
