import 'package:aqua/features/shared/shared.dart';

class CustomError extends HookConsumerWidget {
  const CustomError({Key? key, this.errorMessage}) : super(key: key);

  final String? errorMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 20.h,
      child: errorMessage != null
          ? ErrorLabel(text: errorMessage!)
          : const SizedBox.shrink(),
    );
  }
}
