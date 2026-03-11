import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/providers/providers.dart';
import 'package:ui_components_playground/shared/shared.dart';

class ServiceOptionsDemoPage extends HookConsumerWidget {
  const ServiceOptionsDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final selectedOption = useState<AquaServiceSelectorItemUiModel?>(null);

    final options = useMemoized(
      () => [
        AquaServiceSelectorItemUiModel(
          name: 'BTC Direct',
          fiatAmount: 4558.51,
          convertedAmount: 0.49583344,
          isBestOffer: true,
          icon: AquaIcon.btcDirect(size: 40),
        ),
        AquaServiceSelectorItemUiModel(
          name: 'Changelly',
          fiatAmount: 4558.51,
          convertedAmount: 0.49583344,
          isBestOffer: false,
          icon: AquaIcon.changelly(size: 40),
        ),
        AquaServiceSelectorItemUiModel(
          name: 'Coinbits',
          fiatAmount: 4558.51,
          convertedAmount: 0.49583344,
          isBestOffer: false,
          icon: AquaIcon.coinbits(size: 40),
        ),
      ],
      [],
    );

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 343),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AquaText.h4SemiBold(text: 'Service Options'),
            const SizedBox(height: 20),
            AquaServiceSelector(
              colors: theme.colors,
              options: options,
              selectedOption: selectedOption.value,
              onSelect: (item) => selectedOption.value =
                  selectedOption.value == item ? null : item,
              bestOfferText: 'Best Offer',
            ),
          ],
        ),
      ),
    );
  }
}
