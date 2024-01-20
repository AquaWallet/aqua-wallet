import 'dart:async';

import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SplashScreen extends HookConsumerWidget {
  static const routeName = '/splash';

  const SplashScreen({
    super.key,
    this.description = '',
  });

  final String description;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(systemOverlayColorProvider(context)).aqua();
        ref.invalidate(availableAssetsProvider);
      });
      return null;
    }, []);

    return Stack(
      children: [
        const SplashBackground(),
        Container(
          width: double.maxFinite,
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 10),
              //ANCHOR - Logo
              OnboardingAppLogo(
                description: description,
                onTap: () => unawaited(Navigator.of(context)
                    .pushReplacementNamed(WelcomeScreen.routeName)),
              ),
              const Spacer(flex: 7),
              SizedBox(height: 188.h),
            ],
          ),
        ),
      ],
    );
  }
}
