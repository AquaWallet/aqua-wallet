import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

enum PaymentOption {
  visaMastercard,
  googleApple,
  sepa,
  other,
}

class AquaPaymentRail extends HookWidget {
  const AquaPaymentRail({
    super.key,
    required this.onOptionSelected,
    this.options = PaymentOption.values,
  });

  final Function(PaymentOption option) onOptionSelected;
  final List<PaymentOption> options;

  @override
  Widget build(BuildContext context) {
    final selectedOption = useState(PaymentOption.visaMastercard);
    final optionItems = useMemoized(
      () => {
        if (options.contains(PaymentOption.visaMastercard))
          PaymentOption.visaMastercard: const _VisaMastercardPaymentOption(),
        if (options.contains(PaymentOption.googleApple))
          PaymentOption.googleApple: const _GoogleApplePaymentOption(),
        if (options.contains(PaymentOption.sepa))
          PaymentOption.sepa: const _SepaPaymentOption(),
        if (options.contains(PaymentOption.other))
          PaymentOption.other: const _MorePaymentOption(),
      },
      [],
    );

    useEffect(() {
      onOptionSelected(selectedOption.value);
      return null;
    }, [selectedOption.value]);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        scrollDirection: Axis.horizontal,
        itemCount: optionItems.length,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(width: 4.38),
        itemBuilder: (_, index) => _PaymentOptionListItem(
          isSelected: selectedOption.value == optionItems.keys.elementAt(index),
          onTap: () => selectedOption.value = optionItems.keys.elementAt(index),
          child: optionItems.values.elementAt(index),
        ),
      ),
    );
  }
}

class _PaymentOptionListItem extends StatelessWidget {
  const _PaymentOptionListItem({
    required this.child,
    this.isSelected = false,
    required this.onTap,
  });

  final Widget child;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AquaCard.surface(
      onTap: onTap,
      height: 48,
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _VisaMastercardPaymentOption extends StatelessWidget {
  const _VisaMastercardPaymentOption();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AquaIcon.visa(colored: true, size: 16),
        const SizedBox(width: 2),
        AquaIcon.mastercard(size: 16),
      ],
    );
  }
}

class _GoogleApplePaymentOption extends StatelessWidget {
  const _GoogleApplePaymentOption();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AquaIcon.googlePay(size: 16),
        const SizedBox(width: 3),
        AquaIcon.applePay(size: 16),
      ],
    );
  }
}

class _SepaPaymentOption extends StatelessWidget {
  const _SepaPaymentOption();

  @override
  Widget build(BuildContext context) {
    return AquaIcon.sepa(size: 16);
  }
}

class _MorePaymentOption extends StatelessWidget {
  const _MorePaymentOption();

  @override
  Widget build(BuildContext context) {
    return AquaIcon.more(
      size: 24,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }
}
