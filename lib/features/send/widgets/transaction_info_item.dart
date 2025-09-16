import 'package:coin_cz/gen/fonts.gen.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/material.dart';

class TransactionInfoItem extends StatelessWidget {
  const TransactionInfoItem({
    super.key,
    required this.label,
    required this.value,
    this.padding,
  });

  final String label;
  final String value;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.colors.onBackground,
              fontSize: 14,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w700,
              height: 1.50,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}
