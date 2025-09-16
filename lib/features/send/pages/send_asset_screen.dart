import 'package:coin_cz/features/lightning/lightning.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

enum SendFlowStep {
  address,
  amount,
  review,
}

final _logger = CustomLogger(FeatureFlag.send);

class SendAssetScreen extends HookConsumerWidget {
  const SendAssetScreen({super.key, required this.arguments});

  final SendAssetArguments arguments;

  static const routeName = '/sendAssetScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useState(arguments);
    final input = ref.watch(sendAssetInputStateProvider(args.value));
    final currentStep = useState<SendFlowStep?>(null);

    // Set initial step only once when input first has a value
    useEffect(() {
      if (currentStep.value == null &&
          input.hasValue &&
          input.value?.initialStep != null) {
        currentStep.value = input.value!.initialStep;
      }
      return null;
    }, [input]);

    final stepPages = useMemoized(
      () => [
        SendAssetAddressPage(
          arguments: args.value,
          onContinuePressed: (arguments, address, amount) async {
            args.value = arguments;
            currentStep.value = SendFlowStep.amount;
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
          },
        ),
        SendAssetAmountPage(
          arguments: args.value,
          onContinuePressed: () {
            ref.invalidate(sendAssetFeeOptionsProvider(args.value));
            currentStep.value = SendFlowStep.review;
          },
        ),
        SendAssetReviewPage(
          arguments: args.value,
          onConfirmed: () => ref
              .read(sendAssetTxnProvider(args.value).notifier)
              .executeGdkSendTransaction(),
        ),
      ],
      [args.value],
    );
    final controller = usePageController(
      initialPage: currentStep.value?.index ?? SendFlowStep.address.index,
      keepPage: true,
    );
    final onAppBarBackPressed = useCallback(() {
      final step = currentStep.value;
      if (step == SendFlowStep.address) {
        context.pop();
      } else if (step == SendFlowStep.amount) {
        currentStep.value = SendFlowStep.address;
      } else if (step == SendFlowStep.review) {
        currentStep.value = SendFlowStep.amount;
      }
    }, [currentStep]);

    currentStep.addListener(() {
      controller.animateToPage(
        currentStep.value?.index ?? SendFlowStep.address.index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });

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
          // TODO: Include amount and fee information
          if (args.asset.isLightning) {
            context.push(
              LightningTransactionSuccessScreen.routeName,
              extra: LightningSuccessArguments(
                satoshiAmount: args.amountSats ?? 0,
                type: LightningSuccessType.send,
                orderId: args.serviceOrderId,
              ),
            );
          } else {
            context.push(
              SendAssetTransactionCompleteScreen.routeName,
              extra: args,
            );
          }
        });
      });

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.send,
        showActionButton: false,
        backgroundColor: context.colors.inverseSurfaceColor,
        iconBackgroundColor:
            context.colors.addressFieldContainerBackgroundColor,
        shouldPopOnCustomBack: currentStep.value == SendFlowStep.address,
        onBackPressed: onAppBarBackPressed,
      ),
      // Make sure the Continue button is behind the keyboard
      resizeToAvoidBottomInset: false,
      backgroundColor: context.colors.inverseSurfaceColor,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: controller,
        children: stepPages,
      ),
    );
  }
}
