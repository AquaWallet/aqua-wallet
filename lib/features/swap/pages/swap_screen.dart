import 'dart:developer';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SwapScreen extends HookConsumerWidget {
  static const routeName = '/exchangeSwapScreen';

  const SwapScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resetFormWithError = useCallback((String message) {
      ref.invalidate(sideswapInputStateProvider);
      context.showErrorSnackbar(message);
    }, []);
    ref.listen(
      sideswapWebsocketProvider,
      (_, __) {},
    );
    ref.listen(
      swapDeliverAndReceiveWatcherProvider,
      (_, request) {
        if (request == null) {
          return;
        }

        ref.read(sideswapWebsocketProvider).subscribeAsset(request);
      },
    );
    ref.listen(
      swapAssetsProvider,
      (_, notifier) {
        final assets = notifier.assets;
        if (assets.isEmpty || assets.length < 2) {
          return;
        }

        final deliverAsset = assets.firstWhere((e) => e.isLBTC);
        final receiveAsset = assets.firstWhere((e) => e.id != deliverAsset.id);

        ref.read(sideswapInputStateProvider.notifier)
          ..setDeliverAsset(deliverAsset)
          ..setReceiveAsset(receiveAsset);
      },
    );
    ref.listen(
      swapProvider,
      (_, state) => state.maybeWhen(
        data: (data) => data.maybeWhen(
          pendingVerification: (data) => Navigator.of(context).pushNamed(
            SwapReviewScreen.routeName,
            arguments: data,
          ),
          orElse: () => null,
        ),
        orElse: () {},
      ),
    );
    ref.listen(
      pegProvider,
      (_, state) => state.maybeWhen(
        data: (data) => data.maybeWhen(
          pendingVerification: (data) => Navigator.of(context).pushNamed(
            SwapReviewScreen.routeName,
            arguments: data,
          ),
          orElse: () => null,
        ),
        error: (error, _) => switch (error.runtimeType) {
          PegGdkFeeExceedingAmountException => resetFormWithError(
              AppLocalizations.of(context)!.pegErrorFeeExceedAmount,
            ),
          PegGdkInsufficientFeeBalanceException => resetFormWithError(
              AppLocalizations.of(context)!.pegInsufficientFeeBalanceError,
            ),
          PegGdkTransactionException => resetFormWithError(
              AppLocalizations.of(context)!.pegErrorTransaction,
            ),
          _ => log('[PEG] Error: $error'),
        },
        orElse: () {},
      ),
    );

    return Scaffold(
      appBar: AquaAppBar(
        title: AppLocalizations.of(context)!.swapScreenTitle,
        showActionButton: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      extendBodyBehindAppBar: true,
      body: const SwapPanel(),
    );
  }
}
