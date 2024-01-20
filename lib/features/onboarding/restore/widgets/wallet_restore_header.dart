import 'package:aqua/features/shared/shared.dart';

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
            AppLocalizations.of(context)!.restoreInputTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24.sp,
                  letterSpacing: 1,
                ),
          ),
          SizedBox(height: 16.h),
          if (error) ...{
            Text(
              AppLocalizations.of(context)!.restoreInputError,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          } else ...{
            Text(
              AppLocalizations.of(context)!.restoreInputSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            )
          },
        ],
      ),
    );
  }
}
