import 'package:flutter/material.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/ui_components.dart';

class AquaRadio<T> extends StatelessWidget {
  const AquaRadio({
    super.key,
    required this.value,
    this.onChanged,
    this.groupValue,
    this.enabled = true,
  }) : size = AquaControlSize.large;

  const AquaRadio.small({
    super.key,
    required this.value,
    this.onChanged,
    this.groupValue,
    this.enabled = true,
  }) : size = AquaControlSize.small;

  final T value;
  final T? groupValue;
  final AquaControlSize size;
  final ValueChanged<T>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == groupValue;

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
              color: !isSelected
                  ? Theme.of(context).colorScheme.surfaceContainerHigh
                  : null,
              borderRadius: BorderRadius.circular(100),
            ),
            child: switch (size) {
              AquaControlSize.large => isSelected
                  ? AquaUiAssets.svgs.radioSelected.svg(
                      package: AquaUiAssets.package,
                    )
                  : AquaUiAssets.svgs.radioUnselected.svg(
                      package: AquaUiAssets.package,
                    ),
              AquaControlSize.small => isSelected
                  ? AquaUiAssets.svgs.radioSelectedSmall.svg(
                      package: AquaUiAssets.package,
                    )
                  : AquaUiAssets.svgs.radioUnselectedSmall.svg(
                      package: AquaUiAssets.package,
                    ),
            },
          ),
        ),
      ),
    );
  }
}
