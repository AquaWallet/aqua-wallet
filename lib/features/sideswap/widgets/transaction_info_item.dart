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
            style: Theme.of(context).textTheme.titleSmall,
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
