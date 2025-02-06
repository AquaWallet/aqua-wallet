import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/features/pin/pin_screen.dart';

// Widget that enforces PIN authentication
class PinProtectedScreen extends HookConsumerWidget {
  final Widget child;

  const PinProtectedScreen({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = useState(false);

    if (!isAuthenticated.value) {
      return CheckPinScreen(
        arguments: CheckPinScreenArguments(onSuccessCallback: () {
          isAuthenticated.value = true;
        }),
      );
    }

    return child;
  }
}

// Navigation guard for PIN protection
class PinRouteGuard {
  static Widget guard(Widget child) {
    return PinProtectedScreen(child: child);
  }
}
