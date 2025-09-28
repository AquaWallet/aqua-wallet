import 'package:aqua/features/feature_flags/feature_flags.dart';
import 'package:aqua/features/marketplace/marketplace_tiles/tiles.dart';
import 'package:aqua/features/marketplace/providers/enabled_services_provider.dart';
import 'package:aqua/features/marketplace/widgets/error_retry_button.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_layout_grid/flutter_layout_grid.dart';

class MarketplaceButtonGrid extends HookConsumerWidget {
  const MarketplaceButtonGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var availableServices = ref.watch(enabledServicesTypesProvider);

    // Define all services with their properties
    // To add new services: Create new service type in MarketplaceServiceType,
    // create a new service class in marketplace_services folder, and add it to this map.
    final allServices = useMemoized(() {
      return <MarketplaceServiceType, Widget Function()>{
        MarketplaceServiceType.buyBitcoin: () => const BuyBitcoinTile(),
        MarketplaceServiceType.swaps: () => const SwapsTile(),
        MarketplaceServiceType.btcMap: () => const BtcMapTile(),
        MarketplaceServiceType.debitCard: () => const DebitCardTile(),
      };
    }, []);

    final reload = useCallback(() {
      ref.invalidate(enabledServicesTypesProvider);
    }, [ref]);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: availableServices.when(
          error: (e, _) => ErrorRetryButton(
                onRetry: reload,
              ),
          loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
          data: (services) {
            // Only show enabled services
            final enabledServices = services
                .where((service) => service.isEnabled)
                .map((service) => service.type)
                .map((type) => allServices[type]?.call())
                .whereType<Widget>()
                .toList();

            if (enabledServices.isEmpty) {
              return ErrorRetryButton(
                onRetry: reload,
              );
            }
            return SingleChildScrollView(
              child: LayoutGrid(
                columnSizes: [1.fr, 1.fr],
                rowSizes: List.generate(
                  (enabledServices.length / 2).ceil(),
                  (_) => auto,
                ),
                rowGap: 25.0,
                columnGap: 22.0,
                children: enabledServices,
              ),
            );
          }),
    );
  }
}
