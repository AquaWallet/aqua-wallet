import 'package:aqua/common/widgets/auth_wrapper.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/routes.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'common/debug/navigation_observer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) => runApp(
            ProviderScope(
              overrides: [
                sharedPreferencesProvider.overrideWithValue(prefs),
              ],
              //NOTE - Do NOT remove, for testing various screen sizes
              // child: DevicePreview(
              //   enabled: !kReleaseMode,
              //   builder: (context) => const AquaApp(),
              // ),
              child: const AquaApp(),
            ),
          ));
}

class AquaApp extends HookConsumerWidget {
  const AquaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = ref.watch(prefsProvider.select((p) => p.languageCode));
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

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
      painter: PreloadBackgroundPainter(),
      child: ScreenUtilInit(
        designSize: const Size(428, 926),
        builder: (context, _) => MaterialApp(
          navigatorObservers: [AquaNavigatorObserver()],
          theme: ref.read(lightThemeProvider(context)),
          darkTheme: ref.read(darkThemeProvider(context)),
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
