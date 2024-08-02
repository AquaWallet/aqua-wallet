import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class WelcomeDisclaimerScreen extends HookConsumerWidget {
  const WelcomeDisclaimerScreen({super.key});

  static const routeName = '/welcomeDisclaimer';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.r,
        onActionButtonPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 50.h,
              ),
              Text(
                context.loc.welcomeScreenBetaDisclaimer,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
