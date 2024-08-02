import 'package:flutter/material.dart';

class ConfirmationSlider extends StatefulWidget {
  final double height;
  final double width;
  final Color backgroundColor;
  final Color disabledBackgroundColor;
  final Widget sliderButtonContent;
  final BoxShadow? shadow;
  final String text;
  final TextStyle? textStyle;
  final VoidCallback onConfirmation;
  final VoidCallback? onTapDown;
  final VoidCallback? onTapUp;
  final BorderRadius? backgroundShape;
  final bool stickToEnd;
  final bool enabled;

  final double sliderWidth;
  final double sliderHeight;
  final Widget? backgroundEndContent;

  const ConfirmationSlider({
    super.key,
    required this.height,
    required this.width,
    this.backgroundColor = Colors.white,
    this.disabledBackgroundColor = Colors.grey,
    this.shadow,
    this.sliderButtonContent = const Icon(
      Icons.east,
      color: Colors.white,
    ),
    this.text = '',
    this.textStyle,
    required this.onConfirmation,
    this.onTapDown,
    this.onTapUp,
    this.backgroundShape,
    this.stickToEnd = false,
    this.sliderWidth = 70,
    this.sliderHeight = 70,
    this.backgroundEndContent,
    this.enabled = true,
  });

  @override
  State<StatefulWidget> createState() {
    return ConfirmationSliderState();
  }
}

class ConfirmationSliderState extends State<ConfirmationSlider> {
  double _position = 0;
  int _duration = 0;

  double getPosition() {
    if (_position < 0) {
      return 0;
    } else if (_position > widget.width - widget.sliderWidth) {
      return widget.width - widget.sliderWidth;
    } else {
      return _position;
    }
  }

  void updatePosition(dynamic details) {
    if (details is DragEndDetails) {
      setState(() {
        _duration = 600;
        if (widget.stickToEnd &&
            _position > widget.width - widget.sliderWidth) {
          _position = widget.width - widget.sliderWidth;
        } else {
          _position = 0;
        }
      });
    } else if (details is DragUpdateDetails) {
      setState(() {
        _duration = 0;
        _position = details.localPosition.dx - (widget.sliderWidth);
      });
    }
  }

  void sliderReleased(dynamic details) {
    if (_position > widget.width - widget.sliderWidth) {
      widget.onConfirmation();
    }
    updatePosition(details);
  }

  double calculatePercent() {
    double percent;

    if (_position > widget.width - widget.sliderWidth) {
      percent = 1.0;
    } else if (_position / (widget.width - widget.sliderWidth) > 0) {
      percent = _position / (widget.width - widget.sliderWidth);
    } else {
      percent = 0.0;
    }

    return percent;
  }

  double calculateBackgroundWidth() {
    var width = getPosition() + widget.sliderWidth;

    return width;
  }

  double get textOpacity {
    final opacity = calculatePercent() * 2;
    return 1.0 - (opacity > 1 ? 1 : opacity);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: _duration),
      curve: Curves.ease,
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: widget.backgroundShape ??
            BorderRadius.all(Radius.circular(widget.height)),
        color: widget.enabled
            ? widget.backgroundColor
            : widget.disabledBackgroundColor,
        boxShadow: [
          if (widget.enabled)
            widget.shadow ??
                const BoxShadow(
                  color: Colors.black38,
                  offset: Offset(0, 2),
                  blurRadius: 2,
                  spreadRadius: 0,
                )
        ],
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Opacity(
              opacity: textOpacity,
              child: Text(
                widget.text,
                style: widget.textStyle ??
                    const TextStyle(
                      color: Colors.black26,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: _duration),
            curve: Curves.bounceOut,
            width: calculateBackgroundWidth(),
            height: widget.height,
            child: widget.backgroundEndContent,
          ),
          AnimatedPositioned(
            duration: Duration(milliseconds: _duration),
            curve: Curves.bounceOut,
            left: getPosition(),
            top: 0,
            child: GestureDetector(
              onTapDown: widget.enabled
                  ? (_) => widget.onTapDown != null ? widget.onTapDown!() : null
                  : null,
              onTapUp: widget.enabled
                  ? (_) => widget.onTapUp != null ? widget.onTapUp!() : null
                  : null,
              onPanUpdate:
                  widget.enabled ? (details) => updatePosition(details) : null,
              onPanEnd: widget.enabled
                  ? (details) {
                      if (widget.onTapUp != null) widget.onTapUp!();
                      sliderReleased(details);
                    }
                  : null,
              child: SizedBox(
                width: widget.sliderWidth,
                height: widget.sliderHeight,
                child: widget.sliderButtonContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
