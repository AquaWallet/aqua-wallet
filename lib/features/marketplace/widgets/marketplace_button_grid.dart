import 'package:coin_cz/features/feature_flags/feature_flags.dart';
import 'package:coin_cz/features/marketplace/marketplace_services/services.dart';
import 'package:coin_cz/features/marketplace/models/models.dart';
import 'package:coin_cz/features/marketplace/providers/enabled_services_provider.dart';
import 'package:coin_cz/features/marketplace/widgets/error_retry_button.dart';
import 'package:coin_cz/features/marketplace/widgets/marketplace_button.dart';
import 'package:coin_cz/features/shared/shared.dart';
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
      return <MarketplaceServiceType, MarketplaceService>{
        MarketplaceServiceType.buyBitcoin:
            buildBuyBitcoinService(context: context),
        MarketplaceServiceType.swaps: buildSwapsService(context: context),
        MarketplaceServiceType.btcMap: buildBtcMapService(context: context),
        MarketplaceServiceType.myFirstBitcoin:
            buildMyFirstBitcoinService(context: context),
        MarketplaceServiceType.debitCard:
            buildDebitCardService(context: context),
        // MarketplaceServiceType.giftCards: buildGiftCardsService(context: context)
      };
    }, [context]);

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
                //Only Services enabled by backend
                .where((service) => service.isEnabled)
                // Map to service type
                .map((service) => service.type)
                // Find corresponding service in map.
                .map((type) => allServices[type])
                // Filter out any null values but it should not happen
                .whereType<MarketplaceService>()
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
                children: enabledServices.map((service) {
                  return MarketplaceButton(
                    title: service.title,
                    subtitle: service.subtitle,
                    icon: service.icon,
                    onPressed: service.onPressed,
                  );
                }).toList(),
              ),
            );
          }),
    );
  }
}
