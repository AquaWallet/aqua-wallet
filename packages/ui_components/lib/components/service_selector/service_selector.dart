import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AquaServiceSelectorItemUiModel {
  const AquaServiceSelectorItemUiModel({
    required this.name,
    required this.fiatAmount,
    required this.convertedAmount,
    required this.isBestOffer,
    this.icon,
  });

  final String name;
  final double fiatAmount;
  final double convertedAmount;
  final bool isBestOffer;
  final Widget? icon;
}

class AquaServiceSelector extends HookWidget {
  const AquaServiceSelector({
    super.key,
    required this.options,
    required this.selectedOption,
    required this.onSelect,
    required this.colors,
    required this.bestOfferText,
  });

  final List<AquaServiceSelectorItemUiModel> options;
  final AquaServiceSelectorItemUiModel? selectedOption;
  final void Function(AquaServiceSelectorItemUiModel) onSelect;
  final AquaColors colors;
  final String bestOfferText;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: options.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => AquaDivider(
          colors: colors,
        ),
        itemBuilder: (_, index) {
          final item = options[index];
          return _ServiceProviderListItem(
            onTap: () => onSelect(item),
            isSelected: selectedOption?.name == item.name,
            item: item,
            colors: colors,
            bestOfferText: bestOfferText,
          );
        },
      ),
    );
  }
}

class _ServiceProviderListItem extends StatelessWidget {
  const _ServiceProviderListItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.bestOfferText,
  });

  final AquaServiceSelectorItemUiModel item;
  final bool isSelected;
  final VoidCallback onTap;
  final AquaColors colors;
  final String bestOfferText;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () =>
            WidgetsBinding.instance.addPostFrameCallback((_) => onTap()),
        splashFactory: InkRipple.splashFactory,
        highlightColor:
            isSelected ? Theme.of(context).highlightColor : Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Ink(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected == true ? colors.surfaceSelected : null,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected == true
                    ? colors.surfaceBorderSelected
                    : Colors.transparent,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                item.icon ?? const SizedBox.shrink(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AquaText.body1SemiBold(
                        text: item.name,
                        color: colors.textPrimary,
                      ),
                      if (item.isBestOffer) ...[
                        AquaText.body2Medium(
                          text: bestOfferText,
                          color: colors.accentSuccess,
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AquaText.body1SemiBold(
                      text: '\$${item.fiatAmount}',
                      color: colors.textPrimary,
                    ),
                    AquaText.body2Medium(
                      text: '~${item.convertedAmount} BTC',
                      color: colors.textSecondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
