import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

enum HealthStatus {
  healthy,
  unhealthy,
  unknown,
}

class AquaHealthChecker extends HookConsumerWidget {
  const AquaHealthChecker._({
    super.key,
    this.onTap,
  });

  const AquaHealthChecker.short({
    Key? key,
  }) : this._(
          key: key,
          onTap: null,
        );

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkEvents = ref.watch(networkEventStreamProvider);

    // networkEvents is a list of [liquidState, bitcoinState]
    final isConnected = networkEvents?.maybeWhen(
          data: (events) =>
              events.every((e) => e == GdkNetworkEventStateEnum.connected),
          orElse: () => false,
        ) ??
        false;

    final status = isConnected ? HealthStatus.healthy : HealthStatus.unhealthy;

    final isVisible = status == HealthStatus.unhealthy;

    final color = context.aquaColors.accentDanger;
    final outerColor = context.aquaColors.accentDangerTransparent;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GestureDetector(
          onTap: onTap,
          child: Opacity(
            opacity: isVisible ? 1.0 : 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: outerColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
