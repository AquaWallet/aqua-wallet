import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/config/config.dart';

class AssetStatusIndicator extends ConsumerWidget {
  const AssetStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusIndicatorEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.statusIndicator));

    final status = ref.watch(connectionStatusProvider).asData?.value;

    if (status == null) {
      return const SizedBox.shrink();
    }

    final hasConnectionIssue =
        status.initialized && status.isDeviceConnected != true;

    if (statusIndicatorEnabled && hasConnectionIssue) {
      return Tooltip(
        decoration: BoxDecoration(
          color: Theme.of(context).colors.background,
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
        ),
        richMessage: WidgetSpan(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 8.0,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12.0),
              if (hasConnectionIssue) ...{
                Text(context.loc.connectionStatusOfflineMessage)
              } else if (status.lastBitcoinBlock != null) ...{
                Text(context.loc.connectionStatusBitcoinBlock(
                  status.lastBitcoinBlock!,
                ))
              } else if (status.lastLiquidBlock != null) ...{
                Text(context.loc.connectionStatusLiquidBlock(
                  status.lastLiquidBlock!,
                ))
              }
            ],
          ),
        ),
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          padding: const EdgeInsets.all(4.0),
          child: Icon(
            Icons.cloud_off_rounded,
            size: 24.0,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
