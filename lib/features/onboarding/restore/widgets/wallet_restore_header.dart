import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class WalletRestoreHeader extends StatelessWidget {
  const WalletRestoreHeader({
    super.key,
    required this.error,
  });

  final bool error;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.restoreInputTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 24.0,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 16.0),
          if (error) ...{
            Text(
              context.loc.restoreInputError,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            )
          } else ...{
            Text(
              context.loc.restoreInputSubtitle,
              style: Theme.of(context).textTheme.titleMedium,
            )
          },
        ],
      ),
    );
  }
}
