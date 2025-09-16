import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/receive/receive.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

enum TransactionType {
  send,
  receive,
}

class TransactionMenuScreen extends HookConsumerWidget {
  const TransactionMenuScreen({super.key, required this.type});

  static const routeName = '/transactionMenuScreen';
  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title =
        type == TransactionType.send ? context.loc.send : context.loc.receive;

    final curatedAssets =
        ref.watch(manageAssetsProvider.select((p) => p.curatedAssets));
    final altUSDtAssets = ref.watch(activeAltUSDtsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colors.menuSurface,
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        backgroundColor: Theme.of(context).colors.menuSurface,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        iconOutlineColor: Theme.of(context).colors.appBarIconOutlineColorAlt,
        iconBackgroundColor:
            Theme.of(context).colors.appBarIconBackgroundColorAlt,
        iconForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        title: title,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            //ANCHOR - Description
            Container(
              width: double.infinity,
              height: 500.0,
              decoration: BoxDecoration(
                color: Theme.of(context).colors.menuSurface,
                border: Border.all(
                  color: Theme.of(context).colors.menuSurface,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 24.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 125.0),
                physics: const BouncingScrollPhysics(),
                child: Card(
                  elevation: 0,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20.0),
                      topRight: Radius.circular(20.0),
                    ),
                  ),
                  color: Theme.of(context).colors.menuSurface,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 30.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //ANCHOR - Aqua Assets Section
                        Text(
                          context.loc.receiveMenuScreenSectionAquaAssets,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 26.0),
                        //ANCHOR - Aqua Assets List
                        _AquaAssetsGrid(
                          curatedAssets: curatedAssets,
                          type: type,
                        ),
                        const SizedBox(height: 32.0),
                        if (altUSDtAssets.isNotEmpty) ...[
                          //ANCHOR - Other Assets Section
                          Text(
                            context.loc.receiveMenuScreenSectionOtherAssets,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 26.0),
                          //ANCHOR - Other Assets List
                          _OtherAssetsGrid(
                            otherAssets: altUSDtAssets,
                            type: type,
                          ),
                        ],
                        const SizedBox(height: 32.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            //ANCHOR - Gradient Overlay
            IgnorePointer(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * .25,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).getFadeGradient(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtherAssetsGrid extends ConsumerWidget {
  const _OtherAssetsGrid({
    required this.otherAssets,
    required this.type,
  });

  final List<Asset> otherAssets;
  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisSpacing: 22.0,
      mainAxisSpacing: 27.0,
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: otherAssets
          .map((asset) => _AssetMenuItem(
                name: asset.name,
                symbol: asset.network,
                id: asset.id,
                iconUrl: asset.logoUrl,
                onTap: () {
                  type == TransactionType.send
                      ? context.push(
                          SendAssetScreen.routeName,
                          extra: SendAssetArguments.fromAsset(asset),
                        )
                      : context.push(
                          ReceiveAssetScreen.routeName,
                          extra: ReceiveArguments.fromAsset(asset),
                        );
                },
              ))
          .toList(),
    );
  }
}

class _AquaAssetsGrid extends ConsumerWidget {
  const _AquaAssetsGrid({
    required this.curatedAssets,
    required this.type,
  });

  final List<Asset> curatedAssets;
  final TransactionType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisSpacing: 22.0,
      mainAxisSpacing: 27.0,
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      //ANCHOR - Curated Assets List
      children: curatedAssets
          .map((asset) => _AssetMenuItem(
                name: asset.name,
                symbol: asset.ticker == 'USDt' ? 'Liquid USDt' : asset.ticker,
                id: asset.id,
                iconUrl: asset.logoUrl,
                onTap: () {
                  type == TransactionType.send
                      ? context.push(
                          SendAssetScreen.routeName,
                          extra: SendAssetArguments.fromAsset(asset),
                        )
                      : context.push(
                          ReceiveAssetScreen.routeName,
                          extra: ReceiveArguments.fromAsset(asset),
                        );
                },
              ))
          .toList(),
    );
  }
}

class _AssetMenuItem extends ConsumerWidget {
  const _AssetMenuItem({
    required this.name,
    required this.symbol,
    required this.id,
    required this.iconUrl,
    required this.onTap,
  });

  final String name;
  final String symbol;
  final String id;
  final String iconUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => (p.isDarkMode(context))));
    return AspectRatio(
      aspectRatio: 175 / 164,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colors.listItemBackground,
            borderRadius: BorderRadius.circular(10.0),
            border: darkMode
                ? null
                : Border.all(
                    color: Theme.of(context).colors.cardOutlineColor,
                    width: 2.0,
                  ),
          ),
          child: Opacity(
            opacity: onTap != null ? 1.0 : 0.5,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 7),
                  //ANCHOR - Icon
                  AssetIcon(
                      assetId: id,
                      assetLogoUrl: iconUrl,
                      size:
                          context.adaptiveDouble(smallMobile: 45, mobile: 50)),
                  const SizedBox(height: 35.0),
                  //ANCHOR - Name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: context.adaptiveDouble(
                              smallMobile: 14, mobile: 18.0, wideMobile: 14.0),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 3.0),
                  //ANCHOR - Symbol
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
