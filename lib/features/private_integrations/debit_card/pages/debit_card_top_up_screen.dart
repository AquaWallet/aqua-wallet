import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final _logger = CustomLogger(FeatureFlag.debitCard);

enum TopUpFlowStep {
  amount,
  review,
}

class DebitCardTopUpScreen extends HookConsumerWidget {
  const DebitCardTopUpScreen({super.key});

  static const routeName = '/debitCardTopUp';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useAutomaticKeepAlive();

    final topUpState = ref.watch(topUpInvoiceProvider).valueOrNull!;
    final topUpInput = ref.watch(topUpInputStateProvider).valueOrNull;

    ref.watch(sendAssetInputStateAdapterProvider);
    ref.watch(sendAssetInputStateProvider(topUpState.arguments)).valueOrNull;

    final currentStep = useState(
      topUpInput?.isAmountFieldEmpty ?? true
          ? TopUpFlowStep.amount
          : TopUpFlowStep.review,
    );

    final onAppBarBackPressed = useCallback(() {
      if (currentStep.value == TopUpFlowStep.review) {
        currentStep.value = TopUpFlowStep.amount;
      }
    }, [currentStep]);

    final onExecuteInvoiceTransaction = useCallback(() {
      ref.read(topUpInvoiceProvider.notifier).simulatePayment();
      ref
          .read(sendAssetTxnProvider(topUpState.arguments).notifier)
          .executeGdkSendTransaction();
    }, [topUpState]);

    final stepPages = useMemoized(
      () => [
        DebitCardTopUpAmountPage(
          onInvoiceGenerated: () => currentStep.value = TopUpFlowStep.review,
        ),
        SendAssetReviewPage(
          arguments: topUpState.arguments,
          onConfirmed: onExecuteInvoiceTransaction,
        ),
      ],
      [topUpState.arguments],
    );
    final controller = usePageController(
      initialPage: currentStep.value.index,
      keepPage: true,
    );

    currentStep.addListener(() {
      controller.animateToPage(
        currentStep.value.index,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
      );
    });

    ref.listen(sendAssetTxnProvider(topUpState.arguments), (_, value) {
      value.asData?.value.whenOrNull(complete: (args) {
        _logger.debug("${args.network.name} Top Up Successful: ${args.txId}");
        // Invalidate the moon cards provider to refresh the card list
        ref.invalidate(moonCardsProvider);
        context.replace(
          SendAssetTransactionCompleteScreen.routeName,
          extra: args.copyWith(
            transactionType: SendTransactionType.topUp,
          ),
        );
      });
    });

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        foregroundColor: context.colors.onBackground,
        title: context.loc.topUp,
        shouldPopOnCustomBack: currentStep.value == TopUpFlowStep.amount,
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
