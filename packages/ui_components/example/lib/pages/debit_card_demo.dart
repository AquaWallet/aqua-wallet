import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../providers/providers.dart';

const _kCardNumber = '4738293805948271';
const _cardCvv = '384';

class DebitCardDemoPage extends HookConsumerWidget {
  const DebitCardDemoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AquaText.h4SemiBold(text: 'Carousel'),
          const SizedBox(height: 20),
          Container(
            constraints: const BoxConstraints(
              maxWidth: AquaDebitCard.width + 48,
            ),
            child: AquaCarousel(
              maxContentHeight: AquaDebitCard.height,
              colors: theme.colors,
              children: [
                for (final style in CardStyle.values.take(4)) ...{
                  AquaDebitCard(
                    style: style,
                    expiration: DateTime(2016, 7),
                    pan: _kCardNumber,
                    cvv: _cardCvv,
                  ),
                },
              ],
            ),
          ),
          const SizedBox(height: 20),
          const AquaText.h4SemiBold(text: 'Debit Card'),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final style in CardStyle.values) ...{
                      AquaDebitCard(
                        style: style,
                        expiration: DateTime(2016, 7),
                        pan: _kCardNumber,
                        cvv: _cardCvv,
                      ),
                      const SizedBox(height: 20),
                    }
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final style in CardStyle.values) ...{
                      AquaDebitCard(
                        isRevealed: true,
                        style: style,
                        expiration: DateTime(2016, 7),
                        pan: _kCardNumber,
                        cvv: _cardCvv,
                      ),
                      const SizedBox(height: 20),
                    },
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final style in CardStyle.values) ...{
                      AquaDebitCard(
                        style: style,
                        isReloadable: false,
                        expiration: DateTime(2016, 7),
                        pan: _kCardNumber,
                        cvv: _cardCvv,
                        cardProduct: 'Dolphin Card 1x',
                      ),
                      const SizedBox(height: 20),
                    }
                  ],
                ),
              ),
              const SizedBox(width: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 343),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final style in CardStyle.values) ...{
                      AquaDebitCard(
                        isRevealed: true,
                        isReloadable: false,
                        style: style,
                        expiration: DateTime(2016, 7),
                        pan: _kCardNumber,
                        cvv: _cardCvv,
                        cardProduct: 'Dolphin Card 1x',
                      ),
                      const SizedBox(height: 20),
                    },
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
