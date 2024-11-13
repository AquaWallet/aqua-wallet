import 'dart:io';

import 'package:aqua/constants.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pull_to_refresh_flutter3/pull_to_refresh_flutter3.dart';

class AssetsList extends HookConsumerWidget {
  const AssetsList({
    super.key,
    required this.assets,
  });

  final List<Asset> assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savingAssetList = assets.where((asset) => asset.isBTC).toList();
    final spendingAssetList = assets.where((asset) => !asset.isBTC).toList();
    final refresherKey = useMemoized(UniqueKey.new);
    final controller =
        useMemoized(() => RefreshController(initialRefresh: false));

    return SmartRefresher(
      enablePullDown: true,
      key: refresherKey,
      controller: controller,
      physics: const BouncingScrollPhysics(),
      onRefresh: () async {
        await ref.read(assetsProvider.notifier).reloadAssets();
        controller.refreshCompleted();
      },
      header: ClassicHeader(
        height: 72.h,
        refreshingText: '',
        releaseText: '',
        completeText: '',
        failedText: '',
        idleText: '',
        idleIcon: null,
        failedIcon: null,
        releaseIcon: null,
        refreshingIcon: null,
        completeIcon: null,
        outerBuilder: (child) => Container(child: child),
      ),
      child: ListView(
        padding: EdgeInsets.only(
          left: 28.w,
          right: 28.w,
          bottom: 16.h,
          top: 34.h,
        ),
        primary: false,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        children: [
          SizedBox(height: 12.h),
          //ANCHOR - Savings Header
          AssetListSectionHeader(
            text: context.loc.tabSavings,
          ),
          SizedBox(height: 18.h),
          //ANCHOR - Savings List
          SectionAssetList(items: savingAssetList),
          SizedBox(height: 16.h),
          //ANCHOR - Spending Header
          AssetListSectionHeader(
            text: context.loc.tabSpending,
            children: [
              const Spacer(),
              if (!(Platform.isIOS && disableSideswapOnIOS)) ...{
                const WalletInternalSwapButton(),
              }
            ],
          ),
          SizedBox(height: 18.h),
          //ANCHOR - Spending List
          spendingAssetList.isNotEmpty
              ? SectionAssetList(items: spendingAssetList)
              : AssetListErrorView(
                  message: context.loc.manageAssetsScreenError,
                ),
        ],
      ),
    );
  }
}
