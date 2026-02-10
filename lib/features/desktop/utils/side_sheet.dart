import 'package:aqua/data/provider/provider.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart' show AquaColors;

const _fixedDuration = Duration(milliseconds: 300);
const _barrierLabel = 'Side Sheet';
const _barrierRadius = 0.0;
const _barrierDismissible = true;
const _width = 400.0;

class SideSheet {
  static Future<T?> left<T>({
    required Widget body,
    required BuildContext context,
    required AquaColors colors,
    double width = _width,
    String barrierLabel = _barrierLabel,
    bool barrierDismissible = _barrierDismissible,
    double sheetBorderRadius = _barrierRadius,
    Duration transitionDuration = _fixedDuration,
  }) async =>
      await _showSheetSide(
        body: body,
        width: width,
        rightSide: false,
        context: context,
        barrierLabel: barrierLabel,
        barrierDismissible: barrierDismissible,
        barrierColor: colors.glassSurface,
        sheetBorderRadius: sheetBorderRadius,
        sheetColor: colors.surfaceBackground,
        transitionDuration: transitionDuration,
      );

  static Future<T?> right<T>({
    required Widget body,
    required BuildContext context,
    required AquaColors colors,
    double width = _width,
    String barrierLabel = _barrierLabel,
    bool barrierDismissible = _barrierDismissible,
    double sheetBorderRadius = _barrierRadius,
    Duration transitionDuration = _fixedDuration,
  }) async =>
      _showSheetSide(
        body: body,
        width: width,
        rightSide: true,
        context: context,
        barrierLabel: barrierLabel,
        barrierDismissible: barrierDismissible,
        barrierColor: colors.glassSurface,
        sheetBorderRadius: sheetBorderRadius,
        sheetColor: colors.surfaceBackground,
        transitionDuration: transitionDuration,
      );

  static Future<T?> _showSheetSide<T>({
    required Widget body,
    required bool rightSide,
    double? width,
    required BuildContext context,
    required String barrierLabel,
    required bool barrierDismissible,
    required Color barrierColor,
    required double sheetBorderRadius,
    required Color sheetColor,
    required Duration transitionDuration,
  }) {
    BorderRadius borderRadius = BorderRadius.only(
      topLeft: rightSide ? Radius.circular(sheetBorderRadius) : Radius.zero,
      bottomLeft: rightSide ? Radius.circular(sheetBorderRadius) : Radius.zero,
      topRight: !rightSide ? Radius.circular(sheetBorderRadius) : Radius.zero,
      bottomRight:
          !rightSide ? Radius.circular(sheetBorderRadius) : Radius.zero,
    );

    return showGeneralDialog(
      barrierLabel: barrierLabel,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      transitionDuration: transitionDuration,
      context: context,
      pageBuilder: (context, animation1, animation2) {
        return _DialogWidget(
          borderRadius: borderRadius,
          body: body,
          width: width,
          rightSide: rightSide,
          sheetColor: sheetColor,
        );
      },
      transitionBuilder: (context, animation1, animation2, child) {
        return SlideTransition(
          position: Tween(
            begin: Offset((rightSide ? 1 : -1), 0),
            end: Offset.zero,
          ).animate(animation1),
          child: child,
        );
      },
    );
  }
}

class _DialogWidget extends ConsumerWidget {
  const _DialogWidget({
    required this.borderRadius,
    required this.body,
    required this.sheetColor,
    required this.rightSide,
    this.width,
  });

  final BorderRadius borderRadius;
  final Widget body;
  final double? width;
  final bool rightSide;
  final Color sheetColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Theme(
      data: ref.watch(
        prefsProvider.select(
          (p) => p.isDarkMode(context)
              ? ref.watch(newDarkThemeProvider(context))
              : ref.watch(newLightThemeProvider(context)),
        ),
      ),
      child: Align(
        alignment: (rightSide ? Alignment.centerRight : Alignment.centerLeft),
        child: Material(
          elevation: 15,
          color: Colors.transparent,
          borderRadius: borderRadius,
          child: Container(
            decoration:
                BoxDecoration(color: sheetColor, borderRadius: borderRadius),
            height: double.infinity,
            width: width ?? MediaQuery.of(context).size.width / 1.4,
            child: Material(child: body),
          ),
        ),
      ),
    );
  }
}
