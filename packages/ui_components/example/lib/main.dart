import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_components/gen/ui_localizations.dart';

import 'pages/pages.dart';
import 'providers/providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  runApp(DevicePreview(
    builder: (_) => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const DesignSystemPlaygroundApp(),
    ),
  ));
}

class DesignSystemPlaygroundApp extends HookConsumerWidget {
  const DesignSystemPlaygroundApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      localizationsDelegates: UiLocalizations.localizationsDelegates,
      supportedLocales: UiLocalizations.supportedLocales,
      home: const HomeScreen(),
      routes: {
        NavBarDemoPage.routeName: (context) => const NavBarDemoPage(),
      },
    );
  }
}
