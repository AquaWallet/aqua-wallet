import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

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

  void printNavigationStack() {
    final router = GoRouter.of(this);
    final config = router.routerDelegate.currentConfiguration;
    final matches = config.matches;
    final currentLocation = matches.isNotEmpty
        ? matches.last.route is GoRoute
            ? (matches.last.route as GoRoute).path
            : matches.last.route.toString()
        : config.uri.path;

    logger.debug('[NavigationStack] === Navigation Stack ===');
    logger.debug('[NavigationStack] Current location: $currentLocation');
    logger.debug('[NavigationStack] Base URI: ${config.uri}');
    logger.debug('[NavigationStack] Can pop: ${router.canPop()}');
    logger.debug('[NavigationStack] Full stack (from root to current):');

    for (var i = 0; i < matches.length; i++) {
      final match = matches[i];
      final indent = '  ' * i;
      final route = match.route;
      final routePath = route is GoRoute ? route.path : route.toString();
      final routeName = route is GoRoute ? route.name : null;
      logger.debug(
          '[NavigationStack]$indent[$i] $routePath (${routeName ?? "unnamed"})');
    }

    logger.debug('[NavigationStack] =======================');
  }
}
