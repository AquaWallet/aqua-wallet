import 'package:flutter/material.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

class AquaCheckBox extends StatelessWidget {
  const AquaCheckBox({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  }) : size = AquaControlSize.large;

  const AquaCheckBox.small({
    super.key,
    required this.value,
    this.onChanged,
    this.enabled = true,
  }) : size = AquaControlSize.small;

  final bool value;
  final AquaControlSize size;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled
            ? onChanged != null
                ? () => onChanged!(value)
                : null
            : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            width: size == AquaControlSize.large ? 24 : 18,
            height: size == AquaControlSize.large ? 24 : 18,
            decoration: BoxDecoration(
              color: !value
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: value
                ? AquaUiAssets.svgs.checkboxSelected.svg(
                    package: AquaUiAssets.package,
                  )
                : size == AquaControlSize.small
                    ? AquaUiAssets.svgs.checkboxUnselectedSmall.svg(
                        package: AquaUiAssets.package,
                      )
                    : AquaUiAssets.svgs.checkboxUnselected.svg(
                        package: AquaUiAssets.package,
                      ),
          ),
        ),
      ),
    );
  }
}
