import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';

enum L2TransactionType {
  send,
  receive,
}

class L2SendScreen extends HookConsumerWidget {
  const L2SendScreen({super.key});

  static const routeName = '/l2SendScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type =
        ModalRoute.of(context)!.settings.arguments as L2TransactionType;
    final title = type == L2TransactionType.send
        ? AppLocalizations.of(context)!.sendAssetScreenTitle
        : AppLocalizations.of(context)!.receiveMenuScreenTitle;

    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    final curatedAssets =
        ref.watch(manageAssetsProvider.select((p) => p.curatedAssets));
    curatedAssets.removeWhere((asset) => (!asset.isLightning && !asset.isLBTC));

    return Scaffold(
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
              height: 10.h,
              padding: EdgeInsets.only(left: 30.w, top: 46.h),
              // color: Theme.of(context).colors.menuBackground,
            ),
            SingleChildScrollView(
              padding: EdgeInsets.only(bottom: 125.h),
              physics: const BouncingScrollPhysics(),
              child: Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                ),
                color: Theme.of(context).colors.menuSurface,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 30.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //ANCHOR - Aqua Assets Section
                      Text(
                        AppLocalizations.of(context)!.l2SendScreenTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 26.h),
                      //ANCHOR - Aqua Assets List
                      GridView.count(
                        shrinkWrap: true,
                        crossAxisSpacing: 22.w,
                        mainAxisSpacing: 27.h,
                        crossAxisCount: 2,
                        physics: const NeverScrollableScrollPhysics(),
                        children:
                            //ANCHOR - Curated Assets List
                            curatedAssets
                                .map((asset) => _AssetMenuItem(
                                      name: asset.name,
                                      symbol: asset.ticker == 'USDt'
                                          ? 'Liquid USDt'
                                          : asset.ticker,
                                      id: asset.id,
                                      iconUrl: asset.logoUrl,
                                      onTap: () {
                                        final sendArguments =
                                            SendAssetArguments.fromAsset(asset);
                                        type == L2TransactionType.send
                                            ? Navigator.of(context).pushNamed(
                                                SendAssetScreen.routeName,
                                                arguments: sendArguments,
                                              )
                                            : Navigator.of(context).pushNamed(
                                                ReceiveAssetScreen.routeName,
                                                arguments: asset,
                                              );
                                      },
                                    ))
                                .toList(),
                      ),
                    ],
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

class _AssetMenuItem extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 175 / 164,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: [
              BoxShadow(
                offset: const Offset(0, 1),
                blurRadius: 5,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
          child: Opacity(
            opacity: onTap != null ? 1.0 : 0.5,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
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
                  SizedBox(height: 25.h),
                  //ANCHOR - Name
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  SizedBox(height: 3.h),
                  //ANCHOR - Symbol
                  Text(
                    symbol,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 13.sp,
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
