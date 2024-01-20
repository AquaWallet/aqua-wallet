import 'dart:math';

import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class EntryPointWrapper extends HookConsumerWidget {
  const EntryPointWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final description = useMemoized(() {
      final index = Random().nextInt(4);
      return [
        AppLocalizations.of(context)!.welcomeScreenDesc1,
        AppLocalizations.of(context)!.welcomeScreenDesc2,
        AppLocalizations.of(context)!.welcomeScreenDesc3,
        AppLocalizations.of(context)!.welcomeScreenDesc4,
      ][index];
    });

    final entryPoint = ref.watch(entryPointProvider);

    ref.listen(
      entryPointProvider,
      (_, entryPoint) => entryPoint?.maybeWhen(
        home: () => Navigator.of(context).popUntil((route) => route.isFirst),
        welcome: () {
          //NOTE - Reset to light theme
          Future.microtask(() {
            ref.read(prefsProvider).setTheme(dark: false);
          }).then((_) => Navigator.of(context).popUntil((r) => r.isFirst));
          return null;
        },
        error: (error, __) {
          if (error is AquaProviderBiometricFailureException) {
            SystemNavigator.pop();
          }
          return null;
        },
        orElse: () {
          return null;

          // TODO show error or loading dialog/widget
        },
      ),
    );

    return entryPoint?.maybeWhen(
          home: () => const HomeScreen(),
          welcome: () => WelcomeScreen(description: description),
          orElse: () => SplashScreen(description: description),
        ) ??
        Container();
  }
}
