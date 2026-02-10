import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LinearStepAnimatedProgress extends HookWidget {
  const LinearStepAnimatedProgress({
    super.key,
    required this.aquaColors,
    required this.numberOfSteps,
    required this.numberOfStepsToLoad,
    this.loadingSpeed = const Duration(seconds: 1),
    this.separation = 8.0,
  });

  final AquaColors aquaColors;
  final int numberOfSteps;
  final Duration loadingSpeed;
  final int numberOfStepsToLoad;
  final double separation;

  @override
  Widget build(BuildContext context) {
    final currentStep = useState(0);
    final currentProgress = useState(0.0);
    final isLoading = useState(true);

    final animationController = useAnimationController(
      duration: loadingSpeed,
    );

    final progressAnimation = useAnimation(
      Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: animationController,
          curve: Curves.easeInOut,
        ),
      ),
    );

    // Sequential loading effect
    useEffect(() {
      if (!isLoading.value || currentStep.value >= numberOfStepsToLoad) {
        return null;
      }

      animationController.forward(from: 0.0);

      final timer = Timer(loadingSpeed, () {
        if (currentStep.value < numberOfStepsToLoad - 1) {
          currentStep.value++;
          animationController.reset();
        } else {
          isLoading.value = false;
        }
      });

      return () {
        timer.cancel();
      };
    }, [currentStep.value, isLoading.value]);

    useEffect(() {
      currentProgress.value = progressAnimation;
      return null;
    }, [progressAnimation]);

    double getStepProgress(int stepIndex) {
      if (stepIndex < currentStep.value) {
        return 1.0; // Completed steps
      } else if (stepIndex == currentStep.value) {
        return currentProgress.value; // Loading
      } else {
        return 0.0; // Beginning steps
      }
    }

    return Row(
      children: [
        for (int i = 0; i < numberOfSteps; i++) ...[
          if (i > 0) SizedBox(width: separation),
          Expanded(
            child: LinearProgressIndicator(
              borderRadius: BorderRadius.circular(8),
              value: getStepProgress(i),
              backgroundColor: aquaColors.accentBrandTransparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                aquaColors.accentBrand,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
