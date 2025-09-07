import 'package:aqua/config/config.dart';
import 'package:aqua/config/router/routes.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/foundation.dart';

// Routes that will require the user to be logged in.
// Will redirect to login screen if not logged in.
const requiredLoginRoutes = [
  DebitCardMyCardScreen.routeName,
  DebitCardOnboardingScreen.routeName,
  DebitCardStyleSelectionScreen.routeName,
];

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: routes,
    //NOTE - All redirection logic goes here
    redirect: (context, state) async {
      final auth = ref.read(jan3AuthProvider).valueOrNull;
      final isLoggedIn = auth?.isAuthenticated ?? false;

      if (!isLoggedIn && requiredLoginRoutes.contains(state.matchedLocation)) {
        return state.namedLocation(Jan3LoginScreen.routeName, queryParameters: {
          Jan3LoginScreen.continueTo: state.matchedLocation,
        });
      }

      return null;
    },
    debugLogDiagnostics: kDebugMode,
  );
});
