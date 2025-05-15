import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaLinearProgressIndicator extends HookWidget {
  const AquaLinearProgressIndicator({
    super.key,
    this.height = _minHeight,
    this.barDuration = _barDuration,
    this.intervalDuration = _intervalDuration,
    required this.colors,
  });

  final double height;
  final AquaColors? colors;
  final Duration barDuration;
  final Duration intervalDuration;

  static const _minHeight = 16.0;
  static const _barDuration = Duration(seconds: 2);
  static const _intervalDuration = Duration(seconds: 2);

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
        controller.forward(from: 0).then((_) {
          Future.delayed(intervalDuration, animate);
        });
      }

      animate();
      return null;
    }, const []);

    return Container(
      alignment: Alignment.center,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.sizeOf(context).width,
        minHeight: _minHeight,
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
