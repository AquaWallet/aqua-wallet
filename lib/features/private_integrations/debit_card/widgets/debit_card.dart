import 'dart:math';

import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebitCard extends HookWidget {
  const DebitCard({
    super.key,
    this.card,
    this.isRevealed = false,
  });

  final CardResponse? card;
  final bool isRevealed;

  static const aspectRatio = 372 / 234;

  @override
  Widget build(BuildContext context) {
    // Format the card number with spaces every 4 digits
    final formattedCardNumber = useMemoized(
      () {
        final number = card != null ? card!.pan : List.filled(16, '•').join('');
        return number
            .replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ')
            .trim();
      },
      [card],
    );
    // If not revealed, replace all characters barring the spaces with '•'
    // and keep the last 4 digits
    final fullCardNumber = useMemoized(
      () => isRevealed
          ? formattedCardNumber
          : formattedCardNumber
                  .substring(0, formattedCardNumber.length - 4)
                  .replaceAll(RegExp(r'[^ ]'), '•') +
              formattedCardNumber.substring(formattedCardNumber.length - 4),
      [formattedCardNumber, isRevealed],
    );
    final partialCardNumber = useMemoized(
      () {
        final lastFourDigits = formattedCardNumber.split(' ').lastOrNull ?? '';
        return '${List.filled(4, '•').join('')} $lastFourDigits';
      },
      [formattedCardNumber],
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, child) => Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0)
            ..rotateX(animation.value * pi * -2),
          alignment: Alignment.center,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: ShapeDecoration(
            color: context.colors.debitCardBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: child,
        ),
      ),
      child: isRevealed
          ? _CardBack(
              key: const ValueKey('back'),
              fullCardNumber: fullCardNumber,
              cardExpiry: card?.expiration.formatMonthAndYearNumeric(),
              cardCvv: card?.cvv,
            )
          : _CardFront(
              key: const ValueKey('front'),
              partialCardNumber: partialCardNumber,
              cardStyle: card?.style?.toString()
            ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    super.key,
    required this.partialCardNumber,
    required this.cardStyle,
  });

  final String partialCardNumber;
  final String? cardStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //ANCHOR - Aqua Logo
            UiAssets.svgs.aquaLogo.svg(
              width: 28.98,
              height: 24,
            ),
            //ANCHOR - Card Styled Chip
            if (cardStyle?.isNotEmpty ?? false) ...{
              _LabelChip(label: cardStyle!),
            }
          ],
        ),
        //ANCHOR - Card Chip
        Align(
          alignment: Alignment.topLeft,
          child: UiAssets.svgs.cardChip.svg(
            width: 45,
            height: 33,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //ANCHOR - Partially Revealed Card Number
            Text(
              partialCardNumber,
              style: const TextStyle(
                fontSize: 16,
                fontFamily: UiFontFamily.firaMono,
                fontWeight: FontWeight.w500,
                height: 1,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            //ANCHOR - Visa Logo
            UiAssets.svgs.visa.svg(
              width: 65.26,
              height: 20,
            ),
          ],
        ),
      ],
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({
    super.key,
    required this.fullCardNumber,
    required this.cardExpiry,
    required this.cardCvv,
  });

  final String fullCardNumber;
  final String? cardExpiry;
  final String? cardCvv;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Card Styled Chip
        _LabelChip(label: context.loc.visaReloadable),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Full Card Number
            Text(
              fullCardNumber,
              style: const TextStyle(
                fontSize: 22,
                fontFamily: UiFontFamily.firaMono,
                fontWeight: FontWeight.w500,
                height: 1,
                wordSpacing: -1,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            //ANCHOR - Copy Button
            _CopyButton(content: fullCardNumber),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //ANCHOR - Expiry Date
            _CardInfoItem(
              label: context.loc.expiryDate,
              value: cardExpiry ?? '',
            ),
            const Spacer(),
            //ANCHOR - CVV
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CardInfoItem(
                  label: context.loc.cvv,
                  value: cardCvv ?? '',
                ),
                const SizedBox(width: 14),
                _CopyButton(content: cardCvv ?? ''),
              ],
            ),
            const Spacer(flex: 6),
          ],
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.content,
  });

  final String content;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Clipboard.setData(ClipboardData(text: content)),
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.all(4),
          child: UiAssets.svgs.copy.svg(
            width: 18,
            height: 18,
          ),
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: ShapeDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontFamily: UiFontFamily.inter,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardInfoItem extends StatelessWidget {
  const _CardInfoItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            height: 1,
            fontSize: 8,
            fontFamily: UiFontFamily.inter,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            height: 1,
            fontSize: 18,
            fontFamily: UiFontFamily.firaMono,
            fontWeight: FontWeight.w500,
            shadows: [
              Shadow(
                color: Colors.black26,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
