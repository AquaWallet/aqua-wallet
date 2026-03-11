import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class PaymentRailDemoPage extends StatelessWidget {
  const PaymentRailDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
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
            const AquaText.h4SemiBold(text: 'Payment Rail'),
            const SizedBox(height: 20),
            AquaPaymentRail(
              onOptionSelected: (option) {},
            ),
          ],
        ),
      ),
    );
  }
}
