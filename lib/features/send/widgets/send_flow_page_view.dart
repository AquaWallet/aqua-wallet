import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

int _getPageIndex(SendFlowStep? step) => switch (step) {
      null || SendFlowStep.address => 0,
      SendFlowStep.network => 1,
      SendFlowStep.amount => 2,
      SendFlowStep.review => 3,
    };

class SendFlowPageView extends HookWidget {
  const SendFlowPageView({
    super.key,
    required this.children,
    required this.currentStep,
  });

  final List<Widget> children;
  final SendFlowStep? currentStep;

  @override
  Widget build(BuildContext context) {
    final controller = usePageController(
      initialPage: _getPageIndex(currentStep),
      keepPage: true,
    );

    useEffect(() {
      if (!controller.hasClients) return null;
      final targetIndex = _getPageIndex(currentStep);
      final currentIndex = controller.page?.round() ?? 0;
      if (targetIndex != currentIndex) {
        final distance = (targetIndex - currentIndex).abs();
        final duration = distance > 1
            ? const Duration(milliseconds: 100)
            : const Duration(milliseconds: 200);

        controller.animateToPage(
          targetIndex,
          duration: duration,
          curve: Curves.easeInOut,
        );
      }
      return null;
    }, [currentStep]);

    return PageView(
      physics: const NeverScrollableScrollPhysics(),
      controller: controller,
      children: children,
    );
  }
}
