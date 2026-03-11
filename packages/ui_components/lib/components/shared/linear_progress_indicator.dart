import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaLinearProgressFillIndicator extends HookWidget {
  const AquaLinearProgressFillIndicator({
    super.key,
    this.height = kMinHeight,
    this.fillDuration = _fillDuration,
    this.repeat = false,
    this.onComplete,
    required this.colors,
  });

  final double height;
  final AquaColors? colors;
  final Duration fillDuration;
  final bool repeat;
  final VoidCallback? onComplete;

  static const kMinHeight = 16.0;
  static const _fillDuration = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: fillDuration,
    );

    final progress = useAnimation(
      Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeInOut,
      )),
    );

    useEffect(() {
      void animate() {
        controller.forward(from: 0).whenComplete(() {
          if (context.mounted) {
            onComplete?.call();
            if (repeat) {
              animate();
            }
          }
        });
      }

      animate();
      return null;
    }, [controller, repeat]);

    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
        minHeight: kMinHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 4,
              color: colors?.accentBrandTransparent,
            ),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AquaLinearProgressIndicator extends HookWidget {
  const AquaLinearProgressIndicator({
    super.key,
    this.height = kMinHeight,
    this.barDuration = _barDuration,
    this.intervalDuration = _intervalDuration,
    required this.colors,
  });

  final double height;
  final AquaColors? colors;
  final Duration barDuration;
  final Duration intervalDuration;

  static const kMinHeight = 16.0;
  static const _barDuration = Duration(milliseconds: 500);
  static const _intervalDuration = Duration(milliseconds: 500);

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: barDuration,
    );

    final position = useAnimation(
      Tween<double>(
        begin: -0.3,
        end: 1.3,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.linear,
      )),
    );

    useEffect(() {
      void animate() {
        controller.forward(from: 0).whenComplete(() {
          if (context.mounted) {
            Future.delayed(intervalDuration, animate);
          }
        });
      }

      animate();
      return null;
    }, [controller, intervalDuration]);

    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
        minHeight: kMinHeight,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: 4,
              color: colors?.accentBrandTransparent,
            ),
            FractionallySizedBox(
              widthFactor: 0.3,
              child: Transform.translate(
                offset: Offset(position * MediaQuery.sizeOf(context).width, 0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
