import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';

class AquaNavigatorObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    logger.d('[Navigation] Pushed route: ${route.settings.name}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    logger.d('[Navigation] Popped route: ${route.settings.name}');
  }
}
