import 'dart:ui' as ui;

import 'package:aqua/config/router/go_router.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/provider/isar_export_provider.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/notifications/notifications_service.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/providers/auto_lock_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/lifecycle_observer.dart';
import 'package:aqua/logger.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_components/shared/constants/constants.dart';
import 'package:window_manager/window_manager.dart';

final isAppInBackground = StateProvider<bool>((ref) => false);
final _backgroundStartTime = StateProvider<DateTime?>((ref) => null);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (isDesktop) {
    ///There is additional setup for specific functionality that needs to be followed
    ///For example, Hidden at launch, Quit on close, Confirm before closing, Listening events
    ///here => [https://leanflutter.dev/documentation/window_manager/quick-start]
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(
        minWidthOfDesktopWindow,
        minHeightOfDesktopWindow,
      ),
      size: Size(
        initWidthOfDesktopWindow,
        initHeightOfDesktopWindow,
      ),
      // fullScreen: true,
      center: true,
      title: 'AQUA',
      // skipTaskbar: true,
      titleBarStyle: TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Set orientation immediately to avoid UI jumps
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // Start loading SharedPreferences but don't wait for it
  final prefs = await SharedPreferences.getInstance();

  // Precache the aqua logo SVG to prevent flicker
  await PreloadBackgroundPainter.precacheAquaLogo();

  const needsDevicePreview = String.fromEnvironment('DEVICE_PREVIEW') == 'true';

  // Launch app immediately and handle prefs when they're ready
  runApp(needsDevicePreview
      ? DevicePreview(
          enabled: !kReleaseMode,
          builder: (_) => ProviderScope(
                overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
                child: const AquaApp(),
              ))
      : ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: const AquaApp(),
        ));
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

    final lifecycleCallback = useCallback((AppLifecycleState state) {
      if ([
        AppLifecycleState.inactive,
        AppLifecycleState.paused,
        AppLifecycleState.detached
      ].contains(state)) {
        logger.debug("[Lifecycle] App in background at ${DateTime.now()}");
        ref.read(isAppInBackground.notifier).state = true;
        if (ref.read(_backgroundStartTime) == null) {
          ref.read(_backgroundStartTime.notifier).state = DateTime.now();
        }
      } else if (state == AppLifecycleState.resumed) {
        logger.debug("[Lifecycle] App resumed at ${DateTime.now()}");
        Future.microtask(() async {
          ref.read(isAppInBackground.notifier).state = false;
          final backgroundStartTime = ref.read(_backgroundStartTime);

          logger.debug("[Lifecycle] backgroundStartTime: $backgroundStartTime");

          await ref.read(autoLockProvider).handleAppResume(
                backgroundStartTime: backgroundStartTime,
              );

          ref.read(_backgroundStartTime.notifier).state = null;
        });
      }
    }, []);

    observeAppLifecycle(lifecycleCallback);

    // Defer theme-based operations
    useEffect(() {
      // Use a short delay to prioritize UI rendering first
      Future.delayed(const Duration(milliseconds: 50), () {
        ref.read(systemOverlayColorProvider(context)).themeBased();
      });
      return null;
    }, [theme]);

    // Defer secure storage check and initialize notifications service after initial rendering
    useEffect(
      () {
        // Schedule this operation with a lower priority
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.microtask(() async {
            ref.read(aquaProvider).clearSecureStorageOnReinstall();

            // Initialize notifications service
            final notificationService = ref.read(notificationsServiceProvider);
            await notificationService.initialize();
            await notificationService.createAllNotificationChannels();
          });
        });
        return null;
      },
      [],
    );

    ref.watch(isarExportServiceProvider);
    return CustomPaint(
      painter: PreloadBackgroundPainter(
        isBotevMode: botevMode,
      ),
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
        localizationsDelegates: const [
          ...AppLocalizations.localizationsDelegates,
        ],
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
                if (isInBackground && !isDesktop) ...[
                  BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 25.0, sigmaY: 25.0),
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
