import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapErrorDialogContent extends HookConsumerWidget {
  const SwapErrorDialogContent({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onContinue = useCallback(() {
      ref.invalidate(sideswapInputStateProvider);
      ref.invalidate(sideswapWebsocketProvider);
      Navigator.of(context)
          .popUntil((route) => route.settings.name == SwapScreen.routeName);
    }, []);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context)!.swapError,
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
                  AppLocalizations.of(context)!.backupRecoveryAlertButton,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
