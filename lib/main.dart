import 'dart:ui';

import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/onboarding/shared/shared.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/pages/themes_settings_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/lifecycle_observer.dart';
import 'package:aqua/logger.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger_observer.dart';

final isAppInBackground = StateProvider<bool>((ref) => false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  const needsDevicePreview = String.fromEnvironment('DEVICE_PREVIEW') == 'true';

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    needsDevicePreview
        ? DevicePreview(
            enabled: !kReleaseMode,
            builder: (_) => ProviderScope(
              observers: kDebugMode
                  ? [TalkerRiverpodObserver(talker: logger.internalLogger)]
                  : null,
              overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
              child: const AquaApp(),
            ),
          )
        : ProviderScope(
            observers: kDebugMode
                ? [TalkerRiverpodObserver(talker: logger.internalLogger)]
                : null,
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const AquaApp(),
          ),
  );
}

class AquaApp extends HookConsumerWidget {
  const AquaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(prefsProvider.select((p) => p.languageCode));
    final theme = ref.watch(prefsProvider.select((p) => p.theme));
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
    final isInBackground = ref.watch(isAppInBackground);

    observeAppLifecycle((state) {
      if ([
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.detached
      ].contains(state)) {
        logger.debug("[Lifecycle] App in background");
        Future.microtask(() {
          ref.read(isAppInBackground.notifier).state = true;
        });
      } else if (state == AppLifecycleState.resumed) {
        logger.debug("[Lifecycle] App resumed");
        Future.microtask(() {
          ref.read(isAppInBackground.notifier).state = false;
        });
      }
    });

    useEffect(() {
      Future.microtask(() {
        ref.read(systemOverlayColorProvider(context)).themeBased();
      });
      return null;
    }, [theme]);

    useEffect(
      () {
        ref.read(aquaProvider).clearSecureStorageOnReinstall();
        return null;
      },
      [],
    );
    return CustomPaint(
      painter: PreloadBackgroundPainter(isBotevMode: botevMode),
      child: MaterialApp.router(
        theme: ref.watch(lightThemeProvider(context)),
        darkTheme: ref.watch(darkThemeProvider(context)),
        themeMode: theme == AppTheme.system.name
            ? ThemeMode.system // theme not configured, take system theme
            // theme is configured by user
            : darkMode
                ? ThemeMode.dark
                : ThemeMode.light,
        locale: Locale.fromSubtags(languageCode: languageCode),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        onGenerateTitle: (context) => "AQUA",
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context)
              .copyWith(textScaler: const TextScaler.linear(1));

          return MediaQuery(
            data: mediaQueryData,
            child: Stack(
              children: [
                child!,
                if (isInBackground) ...[
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
                    child: Container(
                      color: Colors.black.withOpacity(0.1),
                    ),
                  )
                ],
              ],
            ),
          );
        },
        routerConfig: ref.read(routerProvider),
      ),
    );
  }
}
