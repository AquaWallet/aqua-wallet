import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class WelcomeDisclaimerScreen extends HookConsumerWidget {
  const WelcomeDisclaimerScreen({super.key});

  static const routeName = '/welcomeDisclaimer';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.0,
        onActionButtonPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 50.0,
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
