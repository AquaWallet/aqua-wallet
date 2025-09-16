import 'package:coin_cz/features/shared/shared.dart';

class CustomError extends HookConsumerWidget {
  const CustomError({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 20.0,
      child: errorMessage != null && errorMessage!.isNotEmpty
          ? ErrorLabel(text: errorMessage!)
          : const SizedBox.shrink(),
    );
  }
}
