import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class ScreenshotWarningSheet extends ConsumerWidget {
  const ScreenshotWarningSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 320.0,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 46.0),
          //ANCHOR - Icon
          SvgPicture.asset(
            Svgs.failure,
            width: 60.0,
            height: 60.0,
          ),
          const SizedBox(height: 20.0),
          //ANCHOR - Title
          Text(
            context.loc.backupRecoveryAlertTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.0,
                ),
          ),
          const SizedBox(height: 8.0),
          //ANCHOR - Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              context.loc.backupRecoveryAlertSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colors.onBackground,
                  ),
            ),
          ),
          const Spacer(),
          //ANCHOR - Quit button
          AquaElevatedButton(
            child: Text(
              context.loc.continueLabel,
            ),
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: 27.0),
        ],
      ),
    );
  }
}
