import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final _logger = CustomLogger(FeatureFlag.send);

class SendAssetScreen extends HookConsumerWidget {
  const SendAssetScreen({super.key, required this.arguments});

  final SendAssetArguments arguments;

  static const routeName = '/sendAssetScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useState(arguments);
    final input = ref.watch(sendAssetInputStateProvider(args.value));
    final currentStep = ref.watch(sendFlowStepProvider);

    useEffect(() {
      final initialStep = input.value?.initialStep;
      if (currentStep == null && input.hasValue && initialStep != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(sendFlowStepProvider.notifier).setStep(initialStep);
        });
      }
      return null;
    }, [input, currentStep]);

    final goToStep = useCallback((SendFlowStep step) {
      ref.read(sendFlowStepProvider.notifier).setStep(step);
    }, []);

    final onAmountSubmit = useCallback(() {
      ref.invalidate(sendAssetFeeOptionsProvider(args.value));
      goToStep(SendFlowStep.review);
    }, [args.value, goToStep]);

    final stepPages = useMemoized(
      () => [
        SendAssetAddressPage(
          arguments: args.value,
          onContinuePressed: (arguments, address, amount) async {
            final inputState =
                ref.read(sendAssetInputStateProvider(args.value)).valueOrNull;

            if (inputState?.isAmbiguousAssets ?? false) {
              goToStep(SendFlowStep.network);
              return;
            }
            if (args.value.asset.id != arguments.asset.id) {
              args.value = arguments;
            }
            //NOTE - This is definately a hack and should be fixed in the future
            // There is scenario where the user selects a non-liquid asset from
            // the transaction menu screen and then provides a liquid asset
            // address, which requires updating the SendAssetArguments args.
            // Due to recreation of SendAssetInputStateProvider with new args,
            // the address field state needs to be updated manually. The delay
            // is to ensure the new SendAssetInputStateProvider is created.
            await Future.delayed(
              const Duration(milliseconds: 50),
              () => ref
                  .read(sendAssetInputStateProvider(args.value).notifier)
                  .updateAddressFieldText(address),
            );
            await Future.delayed(
              const Duration(milliseconds: 50),
              () => ref
                  .read(sendAssetInputStateProvider(args.value).notifier)
                  .updateAmountFieldText(amount),
            );

            // NOTE: Since we are updating the state of the sendAssetInputStateProvider
            // We need to re-read it in order to continue operating that way we ensure
            // its working with the updated state.
            // Even if isAmountEditable casuses revaluation of this steps.
            // The currently running function won't update since the value is closured
            final updatedInput =
                ref.read(sendAssetInputStateProvider(args.value)).valueOrNull;
            if (updatedInput?.isAmountEditable ?? true) {
              goToStep(SendFlowStep.amount);
            } else {
              onAmountSubmit();
            }
          },
        ),
        NetworkSelectionPage(args: args),
        SendAssetAmountPage(
          args: args.value,
          onContinuePressed: onAmountSubmit,
        ),
        SendAssetReviewPage(
          args: args.value,
          onConfirmed: () => ref
              .read(sendAssetTxnProvider(args.value).notifier)
              .executeGdkSendTransaction(),
          onErrorButtonTap: () => ref
              .read(sendFlowStepProvider.notifier)
              .goBack(to: SendFlowStep.amount),
        ),
      ],
      [args.value, goToStep, onAmountSubmit],
    );

    final onAppBarBackPressed = useCallback(() {
      final previousStep = ref.read(sendFlowStepProvider.notifier).goBack();
      if (previousStep == null) {
        context.pop();
      }
    }, []);

    // swap providers
    if (args.value.swapPair != null) {
      ref
        ..listen(swapSetupProvider(SwapArgs(pair: args.value.swapPair!)),
            (_, next) {
          _logger.debug("Swap setup complete: ${next.value}");
        })
        ..listen(swapOrderProvider(SwapArgs(pair: args.value.swapPair!)),
            (_, next) {
          _logger.debug("Swap order created: ${next.value}");
        });
    }

    ref
      //NOTE: Don't remove, keeps the provider alive in addition to logging
      ..listen(sideswapTaxiProvider, (_, next) {
        _logger.debug("Taxi state: ${next.value}");
      })
      ..listen(sendAssetTxnProvider(args.value), (_, value) {
        value.asData?.value.whenOrNull(complete: (args) {
          _logger.debug("${args.network.name} txn complete: ${args.txId}");
          context.push(
            AssetTransactionSuccessScreen.routeName,
            extra: args,
          );
        });
      });

    return PopScope(
      canPop: currentStep == SendFlowStep.address,
      onPopInvoked: (didPop) {
        if (!didPop) {
          onAppBarBackPressed();
        }
      },
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          showBackButton: true,
          title: switch (currentStep) {
            SendFlowStep.review => context.loc.confirmSend,
            SendFlowStep.network => context.loc.selectNetwork,
            _ => context.loc.send,
          },
          colors: context.aquaColors,
          onBackPressed: onAppBarBackPressed,
        ),
        body: SafeArea(
          child: SendFlowPageView(
            children: stepPages,
          ),
        ),
      ),
    );
  }
}
