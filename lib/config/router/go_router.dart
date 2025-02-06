import 'package:aqua/config/config.dart';
import 'package:aqua/config/router/routes.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/foundation.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: routes,
    //NOTE - All redirection logic goes here
    redirect: (context, state) async {
      // If the user is navigating to onboarding screen but already has a token,
      // then redirect to my card screen
      if (state.matchedLocation == DebitCardOnboardingScreen.routeName) {
        final (jan3AuthToken, _) = await ref
            .read(secureStorageProvider)
            .get(Jan3AuthNotifier.tokenKey);
        if (jan3AuthToken != null) {
          return DebitCardMyCardScreen.routeName;
        }
        return null;
      }
      return null;
    },
    debugLogDiagnostics: kDebugMode,
  );
});
