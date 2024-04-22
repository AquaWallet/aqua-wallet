import 'package:aqua/features/shared/shared.dart';

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
      padding: EdgeInsets.symmetric(horizontal: 26.w, vertical: 8.h),
      decoration: BoxDecoration(
        border: Border.all(
          color: color,
          width: 2.r,
        ),
        borderRadius: BorderRadius.circular(30.r),
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
