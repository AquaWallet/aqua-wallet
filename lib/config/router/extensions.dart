import 'package:coin_cz/features/shared/shared.dart';

// Extension for GoRouter till below features are natively supported
extension AquaGoRouterHelper on BuildContext {
  String get _routerlocation {
    final router = GoRouter.of(this);
    final RouteMatch lastMatch =
        router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  void popUntilPath(String routePath) {
    final router = GoRouter.of(this);
    while (_routerlocation != routePath) {
      if (!router.canPop()) {
        return;
      }
      router.pop();
    }
  }

  void maybePop() {
    if (canPop()) {
      pop();
    }
  }
}
