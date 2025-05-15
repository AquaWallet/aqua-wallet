import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

const kSliderTriggerThreshold = 0.75;
const kSliderAnimationDuration = 600;
const kSliderDefaultThumbSize = 56.0;

enum AquaSliderState { initial, inProgress, completed, error }

class AquaSlider extends HookWidget {
  final double height;
  final double width;
  final String text;
  final VoidCallback onConfirm;
  final bool stickToEnd;
  final bool enabled;
  final double thumbWidth;
  final double thumbHeight;
  final AquaSliderState sliderState;

  const AquaSlider({
    super.key,
    required this.width,
    this.height = kSliderDefaultThumbSize,
    this.text = '',
    required this.onConfirm,
    this.stickToEnd = false,
    this.thumbWidth = kSliderDefaultThumbSize,
    this.thumbHeight = kSliderDefaultThumbSize,
    this.enabled = true,
    this.sliderState = AquaSliderState.initial,
  });

  @override
  Widget build(BuildContext context) {
    final position = useState(0.0);
    final animationDuration = useState(0);

    final maxSlidePosition = useMemoized(
      () => width - thumbWidth - 2,
      [width, thumbWidth],
    );

    final getPosition = useCallback(() {
      if (position.value < 0) return 0.0;
      if (position.value > maxSlidePosition) return maxSlidePosition;
      return position.value;
    }, [position.value, maxSlidePosition]);

    final sliderReleased = useCallback((dynamic details) {
      final triggerThreshold = maxSlidePosition * kSliderTriggerThreshold;

      if (position.value > triggerThreshold) {
        // If past 75%, slide to end and trigger callback
        animationDuration.value = kSliderAnimationDuration;
        position.value = maxSlidePosition;
        onConfirm();
      } else {
        // If less than 75%, slide back to start
        animationDuration.value = kSliderAnimationDuration;
        position.value = 0;
      }
    }, [position.value, maxSlidePosition, onConfirm]);

    final updatePosition = useCallback((dynamic details) {
      if (details is DragEndDetails) {
        sliderReleased(details);
      } else if (details is DragUpdateDetails) {
        animationDuration.value = 0;
        position.value = (details.localPosition.dx - thumbWidth) * 2.5;
      }
    }, [sliderReleased, thumbWidth]);

    final currentPosition = useMemoized(
      getPosition,
      [getPosition],
    );

    final percent = useMemoized(
      () => currentPosition / maxSlidePosition,
      [currentPosition, maxSlidePosition],
    );

    final textOpacity = useMemoized(
      () => 1.0 - ((percent * 2).clamp(0.0, 1.0)),
      [percent],
    );

    final backgroundWidth = useMemoized(
      () => currentPosition + thumbWidth,
      [currentPosition, thumbWidth],
    );

    final onPanUpdate = useMemoized(
      () => enabled ? updatePosition : null,
      [enabled, updatePosition],
    );

    final onPanEnd = useMemoized(
      () => enabled ? sliderReleased : null,
      [enabled, sliderReleased],
    );

    final backgroundColorTween = useMemoized(
      () => ColorTween(
        begin: Theme.of(context).colorScheme.surfaceContainerHighest,
        end: Theme.of(context).colorScheme.primary.withOpacity(0),
      ),
      [Theme.of(context)],
    );

    final backgroundColor = useMemoized(
      () =>
          backgroundColorTween.transform(percent) ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      [backgroundColorTween, percent],
    );

    return AnimatedContainer(
      duration: Duration(milliseconds: animationDuration.value),
      curve: Curves.ease,
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: enabled
            ? backgroundColor
            : Theme.of(context).colorScheme.inverseSurface.withOpacity(0.5),
      ),
      child: Stack(
        children: [
          _Label(
            textOpacity: textOpacity,
            color: enabled
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context)
                    .colorScheme
                    .onInverseSurface
                    .withOpacity(0.5),
            text: text,
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: animationDuration.value),
            curve: Curves.bounceOut,
            width: backgroundWidth,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
              ),
              child: Opacity(
                opacity: enabled ? 1.0 : 0.5,
                child: _SliderThumb(state: sliderState),
              ),
            ),
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: animationDuration.value),
            curve: Curves.bounceOut,
            left: currentPosition,
            child: GestureDetector(
              onPanUpdate: onPanUpdate,
              onPanEnd: onPanEnd,
              child: Container(
                color: Colors.transparent,
                width: thumbWidth,
                height: thumbHeight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.textOpacity,
    required this.text,
    required this.color,
  });

  final double textOpacity;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Opacity(
        opacity: textOpacity,
        child: Container(
          padding: const EdgeInsetsDirectional.only(start: 32),
          child: AquaText.body1SemiBold(
            text: text,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _SliderThumb extends StatelessWidget {
  const _SliderThumb({
    required this.state,
  });

  final AquaSliderState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AquaSliderState.initial => AquaUiAssets.svgs.arrow.svg(
          width: 24,
          height: 24,
          fit: BoxFit.scaleDown,
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          package: AquaUiAssets.package,
        ),
      AquaSliderState.inProgress => const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: AquaIndefinateProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
      AquaSliderState.completed => const Icon(
          Icons.check,
          color: Colors.white,
          size: 24,
        ),
      AquaSliderState.error => const Icon(
          Icons.error,
          color: Colors.white,
          size: 24,
        ),
    };
  }
}
