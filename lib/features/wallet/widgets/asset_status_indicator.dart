import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

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
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.all(Radius.circular(4.r)),
        ),
        richMessage: WidgetSpan(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.circle,
                size: 8.r,
                color: Theme.of(context).colorScheme.error,
              ),
              SizedBox(width: 12.w),
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
          padding: EdgeInsets.all(4.r),
          child: Icon(
            Icons.cloud_off_rounded,
            size: 24.r,
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
