import 'package:aqua/common/debug/navigation_observer.dart';
import 'package:aqua/common/widgets/auth_wrapper.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/onboarding/shared/shared.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AppWithDevicePreviewWrapper(),
    ),
  );
}

class AquaApp extends HookConsumerWidget {
  const AquaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(prefsProvider.select((p) => p.languageCode));
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));

    useEffect(() {
      Future.microtask(() {
        ref.read(systemOverlayColorProvider(context)).themeBased();
      });
      return null;
    }, [darkMode]);

    useEffect(
      () {
        ref.read(aquaProvider).clearSecureStorageOnReinstall();
        return null;
      },
      [],
    );

    return CustomPaint(
      painter: PreloadBackgroundPainter(isBotevMode: botevMode),
      child: ScreenUtilInit(
        designSize: const Size(428, 926),
        rebuildFactor: (old, data) => RebuildFactors.always(old, data),
        builder: (context, _) => MaterialApp(
          // ignore: deprecated_member_use
          useInheritedMediaQuery: true,
          navigatorObservers: [AquaNavigatorObserver()],
          theme: ref.watch(lightThemeProvider(context)),
          darkTheme: ref.watch(darkThemeProvider(context)),
          themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
          locale: Locale.fromSubtags(languageCode: languageCode),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (context) => "AQUA",
          onGenerateRoute: (settings) {
            final route = Routes.pages[settings.name];

            if (route == null) {
              assert(false, 'Need to implement ${settings.name}');
              return null;
            }

            return route(settings);
          },
          debugShowCheckedModeBanner: false,
          home: const AuthWrapper(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1),
            child: child!,
          ),
        ),
      ),
    );
  }
}
