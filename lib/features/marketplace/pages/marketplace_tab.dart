import 'package:coin_cz/features/marketplace/marketplace.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class MarketplaceTab extends HookConsumerWidget {
  const MarketplaceTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion =
        ref.watch(regionsProvider.select((p) => p.currentRegion));

    if (selectedRegion != null) {
      return const MarketplaceContent();
    }

    final regionAsyncValue = ref.watch(availableRegionsProvider);

    return regionAsyncValue.maybeWhen(
      data: (data) => const MarketplaceRegionSelection(),
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      orElse: () => MarketplaceErrorView(
        message: context.loc.regionSettingsScreenError,
      ),
    );
  }
}

class MarketplaceContent extends ConsumerWidget {
  const MarketplaceContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(builder: (context, constraints) {
      double screenWidth = constraints.maxWidth;
      double screenHeight = constraints.maxHeight;
      DeviceCategory deviceCategory = ResponsiveBreakpoints.getDeviceCategory(
        screenWidth,
        screenHeight,
      );

      return Scaffold(
        appBar: AquaAppBar(
          showBackButton: false,
          showActionButton: false,
          title: context.loc.marketplaceTitle,
        ),
        body: SafeArea(
          child: SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: MarketplaceView(
              deviceCategory: deviceCategory,
            ),
          ),
        ),
      );
    });
  }
}

class MarketplaceView extends StatelessWidget {
  final DeviceCategory deviceCategory;

  const MarketplaceView({required this.deviceCategory, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Description
        SizedBox(
          height: context.adaptiveDouble(
            smallMobile: 26.0,
            mobile: 60.0,
            tablet: 26.0,
          ),
        ),
        //ANCHOR - Buttons
        const Expanded(child: MarketplaceButtonGrid()),
        SizedBox(
          height: context.adaptiveDouble(
            smallMobile: 4.0,
            mobile: 20.0,
            tablet: 4.0,
          ),
        ),
      ],
    );
  }
}
