import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

int _getPageIndex(SendFlowStep? step) => switch (step) {
      null || SendFlowStep.address => 0,
      SendFlowStep.network => 1,
      SendFlowStep.amount => 2,
      SendFlowStep.review => 3,
    };

class SendFlowPageView extends HookConsumerWidget {
  const SendFlowPageView({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(sendFlowStepProvider);

    final controller = usePageController(
      initialPage: _getPageIndex(currentStep),
      keepPage: true,
    );

    ref.listen(sendFlowStepProvider, (previous, next) {
      final targetIndex = _getPageIndex(next);
      final currentIndex = controller.page?.round() ?? 0;
      final distance = (targetIndex - currentIndex).abs();
      final duration = distance > 1
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 200);

      controller.animateToPage(
        targetIndex,
        duration: duration,
        curve: Curves.easeInOut,
      );
    });

    return PageView(
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      children: children,
    );
  }
}
