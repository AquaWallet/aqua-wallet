import 'dart:math' as math;

import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const _kDotColor = Color(0x4DFFFFFF);
const _kDotColorSparse = Color(0x1AFFFFFF);
const _kShadowColor = Color(0x4D000000);

class GiftBoxWidget extends HookWidget {
  const GiftBoxWidget(
      {super.key, required this.animated, this.floatOffset = 0.0});

  final bool animated;
  final double floatOffset;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );
    final lidOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    final boxOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.33),
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));
    final opacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeIn),
    );

    useEffect(() {
      if (animated) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (controller.isDismissed) controller.forward();
        });
      }
      return null;
    }, const []);

    Widget lid = UiAssets.svgs.lnAddressGiftLid.svg();
    Widget base = UiAssets.svgs.lnAddressGiftBoxBase.svg();

    if (animated) {
      lid = FadeTransition(
        opacity: opacity,
        child: SlideTransition(position: lidOffset, child: lid),
      );
      base = FadeTransition(opacity: opacity, child: base);
    }

    Widget shadow = const CustomPaint(
      size: Size(218.56, 24.48),
      painter: _EllipseShadowPainter(),
    );
    if (animated) {
      shadow = FadeTransition(opacity: opacity, child: shadow);
    }

    Widget boxStack = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Padding(padding: const EdgeInsets.only(top: 30), child: base),
        lid,
      ],
    );

    if (floatOffset != 0.0) {
      boxStack = Transform.translate(
        offset: Offset(0, floatOffset),
        child: boxStack,
      );
    }

    Widget box = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        boxStack,
        shadow,
      ],
    );

    if (animated) {
      box = SlideTransition(position: boxOffset, child: box);
    }

    return box;
  }
}

class _EllipseShadowPainter extends CustomPainter {
  const _EllipseShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    // RadialGradient.createShader maps radius to shortestSide/2, so it only
    // fills a circle — not the full ellipse. We scale x so we work in a square
    // (side = height), draw the gradient there, then the scale stretches it
    // into the correct wide ellipse in screen space.
    canvas.save();
    canvas.scale(size.width / size.height, 1.0);
    final square = Rect.fromLTWH(0, 0, size.height, size.height);
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [_kShadowColor, Colors.transparent],
        radius: 0.45,
      ).createShader(square);
    canvas.drawOval(square, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EllipseShadowPainter old) => false;
}

class GiftDotsBackground extends HookWidget {
  const GiftDotsBackground({super.key, this.sparse = false});

  final bool sparse;

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 4),
    )..repeat();
    return SizedBox.expand(
      child: CustomPaint(
        painter: _DotsPainter(sparse: sparse, animation: controller),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter({this.sparse = false, required this.animation})
      : super(repaint: animation);

  final bool sparse;
  final Animation<double> animation;

  static const _normalDots = [
    (0.15, 0.08, 5.5),
    (0.82, 0.12, 3.5),
    (0.05, 0.25, 2.5),
    (0.90, 0.30, 5.5),
    (0.25, 0.65, 3.5),
    (0.70, 0.60, 2.5),
    (0.10, 0.75, 5.5),
    (0.88, 0.72, 3.5),
    (0.50, 0.88, 2.5),
    (0.35, 0.18, 3.5),
    (0.65, 0.20, 5.5),
    (0.45, 0.45, 2.5),
  ];

  // Fewer dots pushed toward corners/edges, lower opacity
  static const _sparseDots = [
    (0.08, 0.06, 5.5),
    (0.92, 0.10, 3.5),
    (0.03, 0.50, 2.5),
    (0.97, 0.45, 5.5),
    (0.08, 0.92, 3.5),
    (0.90, 0.88, 5.5),
    (0.50, 0.96, 2.5),
  ];

  // Per-dot phase offsets so each dot drifts independently
  static const _phases = [
    0.0,
    0.5,
    1.1,
    1.7,
    2.3,
    2.9,
    3.5,
    4.1,
    4.7,
    5.3,
    0.8,
    1.4
  ];

  static const _driftAmplitude = 4.0; // pixels

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = sparse ? _kDotColorSparse : _kDotColor;
    final dots = sparse ? _sparseDots : _normalDots;
    final t = animation.value * 2 * math.pi;
    for (var i = 0; i < dots.length; i++) {
      final (fx, fy, r) = dots[i];
      final phase = i < _phases.length ? _phases[i] : 0.0;
      final dy = math.sin(t + phase) * _driftAmplitude;
      final dx = math.cos(t * 0.7 + phase) * _driftAmplitude * 0.5;
      canvas.drawCircle(
        Offset(size.width * fx + dx, size.height * fy + dy),
        r,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.sparse != sparse;
}
