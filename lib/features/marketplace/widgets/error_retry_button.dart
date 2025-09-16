import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/features/marketplace/providers/enabled_services_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class ErrorRetryButton extends ConsumerWidget {
  final VoidCallback onRetry;

  const ErrorRetryButton({
    super.key,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(enabledServicesTypesProvider).isLoading;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            Text(
              context.loc.noServicesFound,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            AquaElevatedButton(
              onPressed: isLoading ? null : onRetry,
              child: Text(
                  isLoading ? '${context.loc.loading}...' : context.loc.retry),
            ),
          ],
        ),
      ),
    );
  }
}
