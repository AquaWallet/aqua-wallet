// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/shared/shared.dart';

const _defaultSize = 24.0;

typedef AquaIconBuilder = AquaIcon Function({
  Color? color,
  Key? key,
  VoidCallback? onTap,
  EdgeInsets? padding,
  double size,
});

class AquaIcon extends StatelessWidget {
  const AquaIcon._({
    required this.asset,
    this.color,
    this.onTap,
    this.padding,
  }) : size = _defaultSize;

  AquaIcon.arrowLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowLeft;
  AquaIcon.arrowUp({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowUp;
  AquaIcon.arrowRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowRight;
  AquaIcon.arrowDown({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowDown;
  AquaIcon.arrowDownRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowDownRight;
  AquaIcon.arrowDownLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowDownLeft;
  AquaIcon.arrowUpLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowUpLeft;
  AquaIcon.arrowUpRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.arrowUpRight;
  AquaIcon.chevronDown({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.chevronDown;
  AquaIcon.chevronLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.chevronLeft;
  AquaIcon.chevronUp({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.chevronUp;
  AquaIcon.chevronRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.chevronRight;
  AquaIcon.star({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.star;
  AquaIcon.starFilled({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.starFilled;
  AquaIcon.caret({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.caret;
  AquaIcon.check({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.check;
  AquaIcon.pending({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.pending;

  AquaIcon.notification({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.notification;
  AquaIcon.notificationIndicator({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.notificationIndicator;
  AquaIcon.eyeOpen({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.eyeOpen;
  AquaIcon.eyeClose({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.eyeClose;
  AquaIcon.swap({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.swap;
  AquaIcon.swapVertical({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.swapVertical;
  AquaIcon.scan({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.scan;
  AquaIcon.filter({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.filter;
  AquaIcon.paste({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.paste;
  AquaIcon.danger({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.danger;
  AquaIcon.wallet({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.wallet;
  AquaIcon.hardwareWallet({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.hardwareWallet;
  AquaIcon.aquaIcon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.aquaIcon;
  AquaIcon.aquaLogo({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.aquaLogo;
  AquaIcon.refresh({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.refresh;
  AquaIcon.warning({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.warning;
  AquaIcon.marketplace({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.marketplace;
  AquaIcon.export({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.export;
  AquaIcon.remove({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.remove;
  AquaIcon.images({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.images;
  AquaIcon.settings({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.settings;
  AquaIcon.edit({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.edit;
  AquaIcon.externalLink({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.externalLink;
  AquaIcon.image({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.image;
  AquaIcon.account({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.account;
  AquaIcon.fees({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.fees;
  AquaIcon.lightbulb({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.lightbulb;
  AquaIcon.plus({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.plus;
  AquaIcon.close({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.close;
  AquaIcon.checkCircle({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.checkCircle;
  AquaIcon.logout({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.logout;
  AquaIcon.minus({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.minus;
  AquaIcon.infoCircle({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.infoCircle;
  AquaIcon.more({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.more;
  AquaIcon.language({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.language;
  AquaIcon.history({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.history;
  AquaIcon.share({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.share;
  AquaIcon.rotate({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.rotate;
  AquaIcon.referenceRate({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.referenceRate;
  AquaIcon.spinnerLoading({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.spinnerLoading;
  AquaIcon.box({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.box;
  AquaIcon.map({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.map;
  AquaIcon.theme({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.theme;
  AquaIcon.copy({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.copy;
  AquaIcon.key({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.key;
  AquaIcon.globe({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.globe;
  AquaIcon.biometricFingerprint({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.biometricFingerprint;
  AquaIcon.pokerchip({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.pokerchip;
  AquaIcon.assets({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.assets;
  AquaIcon.pegIn({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.pegIn;
  AquaIcon.passcode({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.passcode;
  AquaIcon.qrIcon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.qrIcon;
  AquaIcon.experimental({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.experimental;
  AquaIcon.switching({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.switching;
  AquaIcon.shield({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.shield;
  AquaIcon.helpSupport({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.helpSupport;
  AquaIcon.redo({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.redo;
  AquaIcon.home({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.home;
  AquaIcon.chart({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.chart;
  AquaIcon.tool({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.tool;
  AquaIcon.user({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.user;
  AquaIcon.search({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.search;
  AquaIcon.sidebarVisibilityLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.sidebarVisibilityLeft;
  AquaIcon.sidebarVisibilityRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.sidebarVisibilityRight;
  AquaIcon.creditCard({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.creditCard;
  AquaIcon.hamburger({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.hamburger;
  AquaIcon.grab({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.grab;
  AquaIcon.trendUp({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.trendUp;
  AquaIcon.statusSuccess({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.statusSuccess;
  AquaIcon.statusWarning({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.statusWarning;
  AquaIcon.statusDanger({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.statusDanger;
  AquaIcon.statusNeutral({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.statusNeutral;
  AquaIcon.contextualIcon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.contextualIcon;
  AquaIcon.visa({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.visa;
  AquaIcon.lock({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.lock;
  AquaIcon.trash({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : asset = AquaUiAssets.svgs.trash;

  final SvgGenImage asset;
  final double size;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashFactory: InkSparkle.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.contains(WidgetState.hovered) &&
              !state.contains(WidgetState.pressed)) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          padding: padding ??
              (onTap != null ? const EdgeInsets.all(4) : EdgeInsets.zero),
          child: asset.svg(
            width: size.toDouble(),
            height: size.toDouble(),
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
          ),
        ),
      ),
    );
  }
}

class AquaAssetIcon extends StatelessWidget {
  const AquaAssetIcon({
    super.key,
    required this.icon,
    this.size = _defaultSize,
    this.color,
    this.padding,
    this.onTap,
  });

  factory AquaAssetIcon.fromAssetId({
    required String assetId,
    double size = _defaultSize,
    final VoidCallback? onTap,
    final EdgeInsets? padding,
    final Color? color,
  }) =>
      switch (assetId) {
        AssetIds.layer2 ||
        _ when (AssetIds.lbtc.contains(assetId)) =>
          AquaAssetIcon.l2Bitcoin(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.btc => AquaAssetIcon.bitcoin(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        _ when (AssetIds.lbtc.contains(assetId)) => AquaAssetIcon.liquidBitcoin(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.lightning => AquaAssetIcon.lightningBtc(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtEth => AquaAssetIcon.usdtEthereum(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        _ when (AssetIds.usdtliquid.contains(assetId)) =>
          AquaAssetIcon.usdtLiquid(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtTrx => AquaAssetIcon.usdtTron(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtBep => AquaAssetIcon.usdtBinance(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtSol => AquaAssetIcon.usdtSolana(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtPol => AquaAssetIcon.usdtPol(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtTon => AquaAssetIcon.usdtTon(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        AssetIds.usdtTether => AquaAssetIcon.usdtTether(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
        _ => AquaAssetIcon.unknown(
            size: size,
            color: color,
            padding: padding,
            onTap: onTap,
          ),
      };

  AquaAssetIcon.bitcoin({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.bitcoin.svg();
  AquaAssetIcon.l2Bitcoin({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.l2Bitcoin.svg();
  AquaAssetIcon.liquidBitcoin({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.liquidBitcoin.svg();
  AquaAssetIcon.lightningBtc({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.lightningBtc.svg();
  AquaAssetIcon.usdtTether({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtTether.svg();
  AquaAssetIcon.usdtLiquid({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtLiquid.svg();
  AquaAssetIcon.usdtEthereum({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtEthereum.svg();
  AquaAssetIcon.usdtTron({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtTron.svg();
  AquaAssetIcon.usdtBinance({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtBinance.svg();
  AquaAssetIcon.usdtSolana({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtSolana.svg();
  AquaAssetIcon.usdtPol({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtPolygon.svg();
  AquaAssetIcon.usdtTon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.usdtTon.svg();
  AquaAssetIcon.ethereum({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.ethereum.svg();
  AquaAssetIcon.binance({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.binance.svg();
  AquaAssetIcon.polygon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.polygon.svg();
  AquaAssetIcon.tron({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.tron.svg();
  AquaAssetIcon.solana({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.solana.svg();
  AquaAssetIcon.ton({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.ton.svg();
  AquaAssetIcon.unknown({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.assetUnknown.svg();
  AquaAssetIcon.fromUrl({
    super.key,
    required String url,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = SvgPicture.network(url);

  final Widget icon;
  final double size;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        splashFactory: InkSparkle.splashFactory,
        overlayColor: WidgetStateProperty.resolveWith((state) {
          if (state.contains(WidgetState.hovered) &&
              !state.contains(WidgetState.pressed)) {
            return Colors.transparent;
          }
          return null;
        }),
        child: Ink(
          padding: padding ??
              (onTap != null ? const EdgeInsets.all(4) : EdgeInsets.zero),
          child: SizedBox(
            width: size,
            height: size,
            child: color != null
                ? ColorFiltered(
                    colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
                    child: icon,
                  )
                : icon,
          ),
        ),
      ),
    );
  }
}
