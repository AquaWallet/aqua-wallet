import 'package:aqua/features/depix/depix.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

int _depixPageIndex(DepixStep? step) => switch (step) {
      null || DepixStep.depositsList => 0,
      DepixStep.amountEntry => 1,
      DepixStep.depositQr => 2,
    };

class DepixScreen extends HookConsumerWidget with GenericErrorPromptMixin {
  const DepixScreen({super.key});

  static const routeName = '/depixAmountEntry';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(depixFlowProvider);

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (currentStep == null) {
          ref.read(depixFlowProvider.notifier).setStep(DepixStep.depositsList);
        }
      });
      return null;
    }, const []);

    final pageController = usePageController(
      initialPage: _depixPageIndex(currentStep),
      keepPage: true,
    );

    ref.listen(depixDepositProvider, (previous, next) {
      if (previous?.isLoading == true) {
        showGenericErrorPromptOnAsyncError(
          context,
          next,
          title: context.loc.depixDepositFailedTitle,
          onPrimaryButtonTap: () =>
              ref.read(depixFlowProvider.notifier).goBack(),
        );
      }
    });

    ref.listen(depixFlowProvider, (_, next) {
      final targetIndex = _depixPageIndex(next);
      final currentIndex = pageController.page?.round() ?? 0;
      final distance = (targetIndex - currentIndex).abs();
      final duration = distance > 1
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 200);
      pageController.animateToPage(
        targetIndex,
        duration: duration,
        curve: Curves.easeInOut,
      );
    });

    final onBackPressed = useCallback(() {
      final currentFlowStep = ref.read(depixFlowProvider);
      if (currentFlowStep == DepixStep.depositQr) {
        ref.read(depixFlowProvider.notifier).goBack(to: DepixStep.depositsList);
        return;
      }
      final previousStep = ref.read(depixFlowProvider.notifier).goBack();
      if (previousStep == null) context.pop();
    }, const []);

    final title = switch (currentStep) {
      DepixStep.depositQr => context.loc.depixDepositQrTitle,
      DepixStep.amountEntry => context.loc.depixAmountEntryTitle,
      _ => context.loc.depixDepositsListTitle,
    };

    return PopScope(
      canPop: currentStep == null || currentStep == DepixStep.depositsList,
      onPopInvoked: (didPop) {
        if (!didPop) onBackPressed();
      },
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          colors: context.aquaColors,
          title: title,
          onBackPressed: onBackPressed,
        ),
        body: SafeArea(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: const [
              DepixDepositsListPage(),
              DepixAmountEntryPage(),
              DepixDepositQrPage(),
            ],
          ),
        ),
      ),
    );
  }
}
