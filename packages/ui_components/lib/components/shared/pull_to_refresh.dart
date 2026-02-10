import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

typedef RefreshCallback = Future<void> Function();

/// Simple pull-to-refresh widget that detects pull gestures
/// and triggers a callback when the user pulls beyond the threshold.
///
/// Can work in two modes:
/// 1. Direct callback mode: Pass [onRefresh] callback directly
/// 2. Controller mode: Pass [controller] to decouple state management
class AquaPullToRefresh extends HookWidget {
  const AquaPullToRefresh({
    super.key,
    required this.child,
    this.onRefresh,
    this.controller,
    this.colors,
    this.enablePullDown = true,
    this.refreshTriggerDistance = kRefreshTriggerDistance,
    this.showIndicator = true,
    this.padding,
  }) : assert(
          (onRefresh != null && controller == null) ||
              (onRefresh == null && controller != null),
          'Either onRefresh or controller must be provided, but not both',
        );

  static const kRefreshTriggerDistance = 100.0;

  final Widget child;
  final RefreshCallback? onRefresh;
  final AquaRefreshController? controller;
  final AquaColors? colors;
  final bool enablePullDown;
  final double refreshTriggerDistance;
  final bool showIndicator;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final isRefreshing = useState(false);
    final isVisible = useState(false);
    final maxPullDistance = useRef(0.0);

    if (!enablePullDown) {
      return child;
    }

    final triggerRefresh = useCallback(() async {
      if (isRefreshing.value) return;

      if (controller != null) {
        await controller!.refresh();
      } else {
        isVisible.value = true;
        isRefreshing.value = true;
        try {
          await onRefresh!();
        } finally {
          isRefreshing.value = false;
        }
      }
    }, [isRefreshing, isVisible, onRefresh, controller]);

    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isRefreshing.value) return false;

        if (notification is ScrollUpdateNotification) {
          final metrics = notification.metrics;
          // Track maximum pull distance during this gesture
          if (metrics.pixels < 0) {
            final distance = -metrics.pixels;
            if (distance > maxPullDistance.value) {
              maxPullDistance.value = distance;
            }
          }
        } else if (notification is ScrollEndNotification) {
          // Check if we pulled far enough when user releases
          if (maxPullDistance.value >= refreshTriggerDistance) {
            triggerRefresh();
          }
          // Reset for next gesture
          maxPullDistance.value = 0.0;
        }

        return false;
      },
      child: Container(
        padding: padding,
        child: Column(
          children: [
            if (showIndicator && controller == null) ...{
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: AquaLinearProgressIndicator.kMinHeight,
                child: AnimatedOpacity(
                  opacity: isVisible.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: isVisible.value
                      ? AquaLinearProgressFillIndicator(
                          colors: colors,
                          // Fade out after fill completes
                          onComplete: () => Future.delayed(
                            const Duration(milliseconds: 100),
                            () => isVisible.value = false,
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              )
            },
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
