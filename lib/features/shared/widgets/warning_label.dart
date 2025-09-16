import 'package:coin_cz/features/shared/shared.dart';

class WarningLabel extends HookConsumerWidget {
  const WarningLabel({
    super.key,
    required this.text,
  });

  final String text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 20.0,
      alignment: Alignment.center,
      child: Row(
        children: [
          const Icon(
            Icons.warning_rounded,
            color: Colors.amber,
            size: 20.0,
          ),
          const SizedBox(width: 4.0),
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
