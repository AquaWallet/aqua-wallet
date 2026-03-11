import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

/// `AquaDropDown` provides a standardized way to display a custom widget
/// as a dropdown, anchored to a UI element.
/// This ensures visual consistency for dropdown menus across the application.
class AquaDropDown {
  // Static final member to manage the currently shown overlay entry.
  static final _currentOverlayEntry = ValueNotifier<OverlayEntry?>(null);

  /// Shows or hides a dropdown menu directly using an OverlayEntry.
  ///
  /// If a dropdown managed by AquaDropDown is already visible, it is removed before
  /// showing the new one. Calling show() again for the same conceptual dropdown
  /// without an intermediate dismiss() effectively replaces it.
  ///
  /// Default styling (padding, border radius, shadow) is applied to the dropdown
  /// container. The [containerWidth] defaults to the anchor's width if available and finite,
  /// otherwise, a fallback width of 200.0 is used. [containerHeight] defaults to 300.0.
  static void show({
    required BuildContext context,
    required Widget child,
    required AquaColors colors,
    RenderObject? anchor,
    double offsetY = 0,
    double? containerWidth,
    double containerHeight = 200,
  }) {
    if (_currentOverlayEntry.value != null) {
      _currentOverlayEntry.value?.remove();
      _currentOverlayEntry.value = null;
    }

    final box = (anchor ?? context.findRenderObject()) as RenderBox?;

    double? effectiveWidth = containerWidth;
    if (effectiveWidth == null && box != null) {
      if (box.hasSize) {
        if (box.size.width < double.infinity) {
          effectiveWidth = box.size.width;
        }
      }
    }
    final finalDropdownWidth = effectiveWidth ?? 240;

    final dropdownContent = ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: containerHeight,
      ),
      child: Container(
        width: finalDropdownWidth,
        decoration: BoxDecoration(
          color: colors.glassSurface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: AquaPrimitiveColors.shadowDark,
              blurRadius: 16,
              offset: Offset(0, 0),
              spreadRadius: 0,
            )
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(8),
          child: AquaCard.glass(
            width: finalDropdownWidth,
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: child,
            ),
          ),
        ),
      ),
    );

    if (box == null) {
      debugPrint('[AquaDropDown] Cannot position the dropdown without anchor.');
      return;
    }

    final buttonPos = box.localToGlobal(Offset.zero);
    double leftAlignment = buttonPos.dx;

    // If the dropdown is narrower than the anchor (and anchor has a finite width),
    // align the right edge of the dropdown with the right edge of the anchor.
    if (box.hasSize &&
        box.size.width.isFinite &&
        finalDropdownWidth < box.size.width) {
      leftAlignment = buttonPos.dx + box.size.width - finalDropdownWidth;
    }

    // Screen boundary adjustments
    final screenWidth = MediaQuery.of(context).size.width;
    const screenEdgePadding = 16.0;

    // Check if dropdown overflows on the right
    if (leftAlignment + finalDropdownWidth > screenWidth - screenEdgePadding) {
      leftAlignment = screenWidth - finalDropdownWidth - screenEdgePadding;
    }

    // Ensure dropdown does not overflow on the left
    if (leftAlignment < screenEdgePadding) {
      leftAlignment = screenEdgePadding;
    }

    // Calculate top position once to use in the Positioned widget
    final topPosition = buttonPos.dy + box.size.height + offsetY;

    final newEntry = OverlayEntry(
      builder: (overlayContext) => Stack(
        children: [
          // Full-screen GestureDetector to detect taps outside the dropdown
          Positioned.fill(
            child: GestureDetector(
              onTap: () => AquaDropDown.dismiss(),
              // Use a transparent color to make it hit-testable.
              // If this is not included, the GestureDetector might not catch taps
              // in empty areas of the Stack.
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),
          // The actual dropdown content, positioned as before
          Positioned(
            top: topPosition,
            left: leftAlignment,
            child: GestureDetector(
              // This GestureDetector absorbs taps on the dropdown itself,
              // preventing the Stack's full-screen detector from dismissing it.
              onTap: () {
                // Do nothing, just absorb the tap on the dropdown content.
              },
              child: dropdownContent,
            ),
          ),
        ],
      ),
    );

    _currentOverlayEntry.value = newEntry;
    Overlay.of(context).insert(newEntry);
  }

  /// Displays a dropdown menu with a list of [items].
  ///
  /// This is a convenience method that uses [AquaDropDown.show] to display
  /// a pre-styled list of tappable string items.
  ///
  /// Parameters:
  /// - [context]: The `BuildContext` from which to show the dropdown.
  /// - [items]: A list of strings to display as menu items. Each item will be
  ///   rendered in an [AquaListItem].
  /// - [anchor]: An optional `RenderObject` to which the dropdown will be
  ///   anchored. If null, the dropdown is positioned based on the `context`.
  ///   Typically, this is the `RenderObject` of the widget that triggers the dropdown.
  /// - [offsetY]: The vertical offset from the anchor. Defaults to 0.
  /// - [containerWidth]: The width of the dropdown container. If null, it defaults
  ///   to a predefined width or the width of the anchor if applicable.
  /// - [containerHeight]: The maximum height of the dropdown container.
  ///   Defaults to 200.
  /// - [showArrow]: Determines whether to show a trailing right chevron icon on
  ///   each menu item. Defaults to true.
  ///
  /// Tapping an item in the menu will print a debug message and dismiss the dropdown.
  static void showMenu({
    required BuildContext context,
    required List<String> items,
    required Function(String item) onItemTap,
    required AquaColors colors,
    RenderObject? anchor,
    double offsetY = 0,
    double containerWidth = 240,
    double containerHeight = 200,
    bool showArrow = true,
  }) {
    show(
      context: context,
      colors: colors,
      anchor: anchor,
      offsetY: offsetY,
      containerWidth: containerWidth,
      containerHeight: containerHeight,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: items.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => Divider(
          height: 1,
          thickness: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        itemBuilder: (context, index) => AquaListItem(
          title: items[index],
          iconTrailing: showArrow
              ? AquaIcon.chevronRight(
                  size: 18,
                  color: Theme.of(context).colorScheme.onSurface,
                )
              : null,
          onTap: () {
            onItemTap(items[index]);
            AquaDropDown.dismiss();
          },
        ),
      ),
    );
  }

  /// Dismisses the currently visible dropdown managed by AquaDropDown.
  static void dismiss() {
    _currentOverlayEntry.value?.remove();
    _currentOverlayEntry.value = null;
  }
}
