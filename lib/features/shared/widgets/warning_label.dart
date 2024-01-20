import 'package:aqua/features/shared/shared.dart';

class WarningLabel extends HookConsumerWidget {
  const WarningLabel({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 20.h,
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Colors.amber,
            size: 20.r,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.amber),
            ),
          ),
        ],
      ),
    );
  }
}
