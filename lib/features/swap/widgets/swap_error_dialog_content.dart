import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
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
      Navigator.of(context)
          .popUntil((route) => route.settings.name == destinationRouteName);
    }, []);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
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
            padding: EdgeInsets.only(top: 24.h),
            child: SizedBox(
              width: double.maxFinite,
              height: 48.h,
              child: BoxShadowElevatedButton(
                onPressed: onContinue,
                child: Text(
                  context.loc.backupRecoveryAlertButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
