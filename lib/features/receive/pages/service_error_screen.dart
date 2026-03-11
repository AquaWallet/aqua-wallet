import 'package:aqua/features/home/pages/home_screen.dart';
import 'package:aqua/features/settings/help_support/pages/help_support_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class ServiceErrorScreen extends StatelessWidget {
  const ServiceErrorScreen({super.key});

  static const routeName = '/serviceErrorScreen';

  @override
  Widget build(BuildContext context) {
    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
        onBackPressed: () => context.go(HomeScreen.routeName),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 100),
                    AquaRingedIcon(
                        icon: AquaIcon.warning(color: Colors.white),
                        variant: AquaRingedIconVariant.warning,
                        colors: context.aquaColors),
                    const SizedBox(height: 24),
                    AquaText.h4Medium(
                      text: context.loc.notAvailableRightNow,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48.0),
                      child: AquaText.body1(
                        color: context.aquaColors.textSecondary,
                        text: context.loc.serviceCurrentlyDown,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
              AquaButton.primary(
                text: context.loc.goBack,
                onPressed: () => context.go(HomeScreen.routeName),
              ),
              const SizedBox(height: 16),
              AquaButton.secondary(
                  text: context.loc.commonContactSupport,
                  onPressed: () => context.push(HelpSupportScreen.routeName))
            ],
          ),
        ),
      ),
    );
  }
}
