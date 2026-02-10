import 'package:aqua/data/data.dart';
import 'package:aqua/features/address_list/address_list.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/receive/models/receive_arguments.dart';
import 'package:aqua/features/receive/pages/receive_asset_screen.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart' hide kAppBarHeight;
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart' hide ResponsiveEx;
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class AssetTransactionsScreen extends HookConsumerWidget {
  const AssetTransactionsScreen({super.key, required this.asset});

  static const routeName = '/assetTransactionsScreen';

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final menuKey = useMemoized(GlobalKey.new);
    final menuItems = useMemoized(
      () => [
        context.loc.addresses,
        if (asset.isUsdtLiquid || asset.isLayerTwo) context.loc.swapOrders,
      ],
      [asset],
    );
    final bottomNavItems = useMemoized(
      () => [
        AquaNavBarItem(
          icon: AquaIcon.arrowDownLeft,
          label: context.loc.receive,
          colors: context.aquaColors,
          onTap: () => asset.isLBTC || asset.isAnyUsdt
              ? context.push(
                  AssetNetworkSelectionScreen.routeName,
                  extra: asset, // Pass the current asset to filter by
                )
              : context.push(
                  ReceiveAssetScreen.routeName,
                  extra: ReceiveArguments.fromAsset(asset),
                ),
        ),
        AquaNavBarItem(
          icon: AquaIcon.arrowUpRight,
          label: context.loc.send,
          colors: context.aquaColors,
          onTap: () => context.push(
            SendAssetScreen.routeName,
            extra: SendAssetArguments.fromAsset(asset),
          ),
        ),
        AquaNavBarItem(
          icon: AquaIcon.scan,
          label: context.loc.scan,
          colors: context.aquaColors,
          onTap: () async {
            final result = await context.push(
              ScanScreen.routeName,
              extra: ScanArguments(
                qrArguments: QrScannerArguments(
                  asset: asset,
                  parseAction: QrScannerParseAction.attemptToParse,
                ),
                textArguments: TextScannerArguments(
                  asset: asset,
                  parseAction: TextScannerParseAction.attemptToParse,
                ),
                initialType: ScannerType.qr,
              ),
            );

            // Handle QR scan result
            if (result is QrScanState) {
              result.maybeWhen(
                sendAsset: (args) {
                  context.push(SendAssetScreen.routeName, extra: args);
                },
                orElse: () {},
              );
            }
            // Handle text scan result
            else if (result is String) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.push(
                  SendAssetScreen.routeName,
                  extra: SendAssetArguments.fromAsset(asset).copyWith(
                    input: result,
                  ),
                );
              });
            }
          },
        ),
      ],
      [context.aquaColors],
    );

    ref
      ..listen(sideswapWebsocketProvider, (_, __) {})
      ..listen(swapAssetsProvider, (_, __) {});

    return AnnotatedRegion(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: context.aquaColors.glassBackground,
        systemNavigationBarContrastEnforced: true,
      ),
      child: DesignRevampScaffold(
        extendBodyBehindAppBar: true,
        appBar: AquaTopAppBar(
          title: asset.isLBTC ? context.loc.layer2Bitcoin : asset.name,
          onBackPressed: () {
            final router = GoRouter.of(context);
            if (router.canPop()) {
              context.pop();
            } else {
              context.go(HomeScreen.routeName);
            }
          },
          actions: [
            AquaIcon.more(
              key: menuKey,
              color: context.aquaColors.textPrimary,
              onTap: () => AquaDropDown.showMenu(
                context: context,
                colors: context.aquaColors,
                anchor: menuKey.currentContext?.findRenderObject(),
                items: menuItems,
                onItemTap: (item) {
                  if (item == context.loc.addresses) {
                    context.push(
                      AddressListScreen.routeName,
                      extra: AddressListArgs(
                        networkType: asset.isBTC
                            ? NetworkType.bitcoin
                            : NetworkType.liquid,
                        asset: asset,
                      ),
                    );
                  } else if (item == context.loc.swapOrders) {
                    if (asset.isUsdtLiquid) {
                      context.push(SwapOrdersScreen.routeName);
                    } else if (asset.isLayerTwo) {
                      context.push(BoltzSwapsScreen.routeName);
                    }
                  }
                },
              ),
            )
          ],
          colors: context.aquaColors,
        ),
        bottomNavigationBar: AquaNavBar(
          colors: context.aquaColors,
          itemCount: bottomNavItems.length,
          itemBuilder: (_, index) => bottomNavItems[index],
        ),
        extendBody: true,
        body: AssetTransactions(asset: asset),
      ),
    );
  }
}
