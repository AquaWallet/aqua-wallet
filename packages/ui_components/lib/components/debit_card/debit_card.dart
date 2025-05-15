import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class AquaDebitCard extends HookWidget {
  const AquaDebitCard({
    super.key,
    required this.expiration,
    required this.pan,
    required this.cvv,
    this.style = CardStyle.style1,
    this.isRevealed = false,
    this.isReloadable = true,
    this.cardProduct = defaultName,
  });

  final DateTime expiration;
  final String pan;
  final String cvv;
  final CardStyle style;
  final bool isRevealed;
  final String cardProduct;
  final bool isReloadable;

  static const keyCardBack = ValueKey('back');
  static const keyCardFront = ValueKey('front');

  static const double width = 343;
  static const double height = 218;
  static const double aspectRatio = width / height;
  static const String defaultName = 'Dolphin';

  @override
  Widget build(BuildContext context) {
    final cardFlipController = useMemoized(FlipCardController.new);
    final frontImage = useMemoized(
      style.frontImage.provider,
      [style],
    );
    final backImage = useMemoized(
      () => style.backImage.provider(),
      [style],
    );
    final isRevealed = useState(this.isRevealed);
    // Format the card number with spaces every 4 digits
    final formattedCardNumber = useMemoized(
      () {
        final number = pan;
        return number
            .replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ')
            .trim();
      },
      [pan],
    );
    // If not revealed, replace all characters barring the spaces with '•'
    // and keep the last 4 digits
    final fullCardNumber = useMemoized(
      () => isRevealed.value
          ? formattedCardNumber
          : formattedCardNumber
                  .substring(0, formattedCardNumber.length - 4)
                  .replaceAll(RegExp(r'[^ ]'), '•') +
              formattedCardNumber.substring(formattedCardNumber.length - 4),
      [formattedCardNumber, isRevealed.value],
    );
    final partialCardNumber = useMemoized(
      () {
        final lastFourDigits = formattedCardNumber.split(' ').lastOrNull ?? '';
        return '${List.filled(4, '•').join('')} $lastFourDigits';
      },
      [formattedCardNumber],
    );

    useEffect(() {
      if (isRevealed.value) {
        cardFlipController.flipcard();
      }
      return null;
    }, []);

    final cardFront = _CardContainer(
      onTap: cardFlipController.flipcard,
      image: frontImage,
      child: _CardFront(
        key: keyCardFront,
        partialCardNumber: partialCardNumber,
        cardProduct: cardProduct,
      ),
    );
    final cardBack = _CardContainer(
      onTap: cardFlipController.flipcard,
      image: backImage,
      child: _CardBack(
        key: keyCardBack,
        fullCardNumber: fullCardNumber,
        cardExpiry: DateFormat('MM/yy').format(expiration),
        cardCvv: cvv,
        isReloadable: isReloadable,
      ),
    );
    return FlipCard(
      onTapFlipping: false,
      axis: FlipAxis.horizontal,
      rotateSide: RotateSide.top,
      controller: cardFlipController,
      animationDuration: const Duration(milliseconds: 300),
      frontWidget: isRevealed.value ? cardBack : cardFront,
      backWidget: isRevealed.value ? cardFront : cardBack,
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    super.key,
    required this.partialCardNumber,
    required this.cardProduct,
  });

  final String partialCardNumber;
  final String cardProduct;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //ANCHOR - Aqua Logo
            AquaIcon.aquaIcon(
              size: 29,
              color: Colors.white,
            ),
            //ANCHOR - Card Styled Chip
            _LabelChip(label: cardProduct),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            //ANCHOR - Partially Revealed Card Number
            Text(
              partialCardNumber,
              style: AquaCreditCardTypography.body1.copyWith(
                shadows: [
                  const Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            //ANCHOR - Visa Logo
            SizedBox(
              width: 65.26,
              height: 20,
              child: AquaIcon.visa(
                size: 65.26,
                color: Colors.white,
              ),
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
    required this.isReloadable,
  });

  final String fullCardNumber;
  final String? cardExpiry;
  final String? cardCvv;
  final bool isReloadable;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Card Styled Chip
        _LabelChip(
          label:
              isReloadable ? context.loc.reloadable : context.loc.nonReloadable,
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //ANCHOR - Full Card Number
            Text(
              fullCardNumber,
              style: AquaCreditCardTypography.body1.copyWith(
                fontSize: context.adaptiveDouble(
                  mobile: 18,
                  smallMobile: 16,
                ),
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
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
            const SizedBox(width: 32),
            //ANCHOR - CVV
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _CardInfoItem(
                  label: context.loc.cvv,
                  value: cardCvv ?? '',
                ),
                const SizedBox(width: 12),
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

class _CardContainer extends StatelessWidget {
  const _CardContainer({
    required this.image,
    required this.child,
    required this.onTap,
  });

  final ImageProvider<Object> image;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AquaDebitCard.width,
        height: AquaDebitCard.height,
        padding: const EdgeInsets.all(24),
        decoration: ShapeDecoration(
          image: DecorationImage(
            image: image,
            fit: BoxFit.cover,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 0),
              spreadRadius: 0,
            )
          ],
        ),
        child: child,
      ),
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
          child: AquaIcon.copy(
            size: 18,
            color: Colors.white,
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
      padding: const EdgeInsets.symmetric(
        vertical: 4,
        horizontal: 8,
      ),
      decoration: BoxDecoration(
        color: AquaColors.lightColors.glassBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: AquaText.caption1SemiBold(
        text: label,
        color: Colors.white,
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
          style: AquaTypography.body1SemiBold.copyWith(
            color: Colors.white,
            letterSpacing: 0,
            wordSpacing: -2,
            fontSize: context.adaptiveDouble(
              mobile: 8,
              smallMobile: 6,
            ),
          ),
        ),
        Text(
          value,
          style: AquaCreditCardTypography.body1.copyWith(
            letterSpacing: 1.25,
            color: Colors.white,
            fontSize: context.adaptiveDouble(
              mobile: 18,
              smallMobile: 16,
            ),
            shadows: const [
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
