import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class WalletProcessError extends ConsumerWidget {
  const WalletProcessError({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomAlertDialog(
      title: context.loc.unknownErrorTitle,
      subtitle: context.loc.unknownErrorSubtitle,
      controlWidgets: [
        Expanded(
          child: ElevatedButton(
            child: Text(context.loc.retry),
            onPressed: () => context.pop(),
          ),
        ),
      ],
    );
  }
}
