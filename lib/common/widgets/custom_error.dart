import 'package:aqua/features/shared/shared.dart';

class CustomError extends HookConsumerWidget {
  const CustomError({super.key, this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 20.h,
      child: errorMessage != null && errorMessage!.isNotEmpty
          ? ErrorLabel(text: errorMessage!)
          : const SizedBox.shrink(),
    );
  }
}
