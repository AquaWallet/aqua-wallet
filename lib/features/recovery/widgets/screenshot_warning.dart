import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class ScreenshotWarningSheet extends ConsumerWidget {
  const ScreenshotWarningSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 320.h,
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 46.h),
          //ANCHOR - Icon
          SvgPicture.asset(
            Svgs.failure,
            width: 60.r,
            height: 60.r,
          ),
          SizedBox(height: 20.h),
          //ANCHOR - Title
          Text(
            context.loc.backupRecoveryAlertTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.sp,
                ),
          ),
          SizedBox(height: 8.h),
          //ANCHOR - Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              context.loc.backupRecoveryAlertSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
          ),
          const Spacer(),
          //ANCHOR - Quit button
          AquaElevatedButton(
            child: Text(
              context.loc.backupRecoveryAlertButton,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          SizedBox(height: 27.h),
        ],
      ),
    );
  }
}
