import 'package:aqua/config/router/extensions.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapErrorDialogContent extends HookConsumerWidget {
  const SwapErrorDialogContent({
    super.key,
    required this.message,
    this.destinationRouteName = SwapScreen.routeName,
  });

  final String message;
  final String destinationRouteName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onContinue = useCallback(() {
      ref.invalidate(sideswapInputStateProvider);
      ref.invalidate(sideswapWebsocketProvider);
      context.popUntilPath(destinationRouteName);
    }, []);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            context.loc.swapError,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 24.0),
            child: SizedBox(
              width: double.maxFinite,
              height: 48.0,
              child: BoxShadowElevatedButton(
                onPressed: onContinue,
                child: Text(
                  context.loc.continueLabel,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
