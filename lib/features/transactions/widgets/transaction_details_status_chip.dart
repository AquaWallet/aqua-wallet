import 'package:coin_cz/features/shared/shared.dart';

class TransactionDetailsStatusChip extends StatelessWidget {
  const TransactionDetailsStatusChip({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 8.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: color,
            ),
      ),
    );
  }
}
