import 'dart:math';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

const _kAnimationDuration = Duration(milliseconds: 200);

class InternalSendMenu extends HookConsumerWidget {
  const InternalSendMenu({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);
    final assets = ref.watch(assetsProvider).asData?.value ?? [];
    final btcAsset = useMemoized(
      () => assets.firstWhere((a) => a.isBTC),
      [assets],
    );
    final lbtcAsset = useMemoized(
      () => assets.firstWhere((a) => a.isLBTC),
      [assets],
    );
    final usdtAsset = useMemoized(
      () => assets.firstWhereOrNull((a) => a
          .isUsdtLiquid), // usdt can be null if removed from assets list by user
      [assets],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        //ANCHOR - Internal Swap Title
        GestureDetector(
          onTap: () => isExpanded.value = !isExpanded.value,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.loc.internalSend,
                textAlign: TextAlign.left,
                style: context.textTheme.headlineSmall?.copyWith(
                  fontSize: 22.0,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(width: 8),
              Transform.rotate(
                angle: isExpanded.value ? 0 : pi / -2,
                child: UiAssets.svgs.chevronDown.svg(
                  width: 10,
                  height: 6,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16.0),

        //ANCHOR - Internal Swap Buttons
        AnimatedOpacity(
          opacity: isExpanded.value ? 1 : 0,
          duration: _kAnimationDuration,
          child: AnimatedSize(
            duration: _kAnimationDuration,
            child: Column(
              children: isExpanded.value
                  ? [
                      if (asset.isBTC) ...{
                        _InternalSendCard(
                          deliverAsset: btcAsset,
                          receiveAsset: lbtcAsset,
                        ),
                      },
                      if (asset.isUsdtLiquid && usdtAsset != null) ...{
                        _InternalSendCard(
                          deliverAsset: usdtAsset,
                          receiveAsset: lbtcAsset,
                        ),
                      },
                      if (asset.isLBTC && usdtAsset != null) ...[
                        _InternalSendCard(
                          deliverAsset: lbtcAsset,
                          receiveAsset: usdtAsset,
                        ),
                        const SizedBox(height: 15.0),
                      ],
                      if (asset.isLBTC) ...{
                        _InternalSendCard(
                          deliverAsset: lbtcAsset,
                          receiveAsset: btcAsset,
                        ),
                      },
                    ]
                  : [],
            ),
          ),
        ),
      ],
    );
  }
}

class _InternalSendCard extends HookConsumerWidget {
  const _InternalSendCard({
    required this.deliverAsset,
    required this.receiveAsset,
  });

  final Asset deliverAsset;
  final Asset receiveAsset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(10.0),
      bordered: !darkMode,
      borderColor: Theme.of(context).colors.cardOutlineColor,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          //ANCHOR - Navigate to Internal Send screen
          onTap: () => context.push(
            InternalSendAmountScreen.routeName,
            extra: InternalSendArguments.amount(
              deliverAsset: deliverAsset,
              receiveAsset: receiveAsset,
            ),
          ),
          splashColor: Colors.transparent,
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                //ANCHOR - Icon
                SizedBox.square(
                  dimension: 50.0,
                  child: receiveAsset.isLBTC
                      ? SvgPicture.asset(
                          Svgs.layerTwoSingle,
                          width: 50.0,
                          height: 50.0,
                        )
                      : AssetIcon(
                          assetId: receiveAsset.id,
                          assetLogoUrl: receiveAsset.logoUrl,
                          fit: BoxFit.contain,
                          size: 50.0,
                        ),
                ),
                const SizedBox(width: 12.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //ANCHOR - Name
                    Text(
                      receiveAsset.isLBTC
                          ? context.loc.internalSendLbtcTitle
                          : receiveAsset.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 18.0,
                            letterSpacing: 0.4,
                          ),
                    ),
                    //ANCHOR - Symbol
                    Text(
                      receiveAsset.isLBTC
                          ? context.loc.internalSendLbtcSubtitle
                          : receiveAsset.isUsdtLiquid
                              ? context.loc.internalSendUsdtSubtitle
                              : receiveAsset.ticker,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13.0,
                            letterSpacing: 0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
