import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

enum TransactionType {
  send,
  receive,
}

class TransactionMenuScreen extends HookConsumerWidget {
  const TransactionMenuScreen({super.key});

  static const routeName = '/transactionMenuScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type = ModalRoute.of(context)!.settings.arguments as TransactionType;
    final title = type == TransactionType.send
        ? context.loc.sendAssetScreenTitle
        : context.loc.receiveMenuScreenTitle;

    final curatedAssets =
        ref.watch(manageAssetsProvider.select((p) => p.curatedAssets));
    final otherAssets = ref
        .watch(manageAssetsProvider.select((p) => p.otherTransactableAssets));

    return PopScope(
      canPop: true,
      onPopInvoked: (_) => ref.invalidate(receiveAssetAddressProvider),
      child: Scaffold(
        backgroundColor: Theme.of(context).colors.menuSurface,
        appBar: AquaAppBar(
          showBackButton: true,
          showActionButton: false,
          backgroundColor: Theme.of(context).colors.menuBackground,
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
                height: 500.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).colors.menuBackground,
                  border: Border.all(
                    color: Theme.of(context).colors.menuBackground,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 24.h),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(bottom: 125.h),
                  physics: const BouncingScrollPhysics(),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.r),
                        topRight: Radius.circular(20.r),
                      ),
                    ),
                    color: Theme.of(context).colors.menuSurface,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 28.w,
                        vertical: 30.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          //ANCHOR - Aqua Assets Section
                          Text(
                            context.loc.receiveMenuScreenSectionAquaAssets,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 26.h),
                          //ANCHOR - Aqua Assets List
                          _AquaAssetsGrid(
                            curatedAssets: curatedAssets,
                            type: type,
                          ),
                          SizedBox(height: 32.h),
                          if (otherAssets.isNotEmpty) ...[
                            //ANCHOR - Other Assets Section
                            Text(
                              context.loc.receiveMenuScreenSectionOtherAssets,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            SizedBox(height: 26.h),
                            //ANCHOR - Other Assets List
                            _OtherAssetsGrid(
                              otherAssets: otherAssets,
                              type: type,
                            ),
                          ],
                          SizedBox(height: 32.h),
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
      crossAxisSpacing: 22.w,
      mainAxisSpacing: 27.h,
      crossAxisCount: 2,
      physics: const NeverScrollableScrollPhysics(),
      children: otherAssets
          .map((asset) => _AssetMenuItem(
                name: asset.name,
                symbol: asset.isEth ? 'Ethereum USDt' : 'Tron USDt',
                id: asset.id,
                iconUrl: asset.logoUrl,
                onTap: () {
                  final sendArguments = SendAssetArguments.fromAsset(asset);
                  type == TransactionType.send
                      ? ref
                          .read(sendNavigationEntryProvider(sendArguments))
                          .call(context)
                      : Navigator.of(context).pushNamed(
                          ReceiveAssetScreen.routeName,
                          arguments: asset,
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
      crossAxisSpacing: 22.w,
      mainAxisSpacing: 27.h,
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
                  final sendArguments = SendAssetArguments.fromAsset(asset);
                  type == TransactionType.send
                      ? ref
                          .read(sendNavigationEntryProvider(sendArguments))
                          .call(context)
                      : Navigator.of(context).pushNamed(
                          ReceiveAssetScreen.routeName,
                          arguments: asset,
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
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    return AspectRatio(
      aspectRatio: 175 / 164,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            border: darkMode
                ? null
                : Border.all(
                    color: Theme.of(context).colors.cardOutlineColor,
                    width: 2.w,
                  ),
          ),
          child: Opacity(
            opacity: onTap != null ? 1.0 : 0.5,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 19.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  //ANCHOR - Icon
                  AssetIcon(
                    assetId: id,
                    assetLogoUrl: iconUrl,
                    size: 60.r,
                  ),
                  SizedBox(height: 35.h),
                  //ANCHOR - Name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: context.adaptiveDouble(
                              mobile: 18.sp, wideMobile: 14.sp),
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 3.h),
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
