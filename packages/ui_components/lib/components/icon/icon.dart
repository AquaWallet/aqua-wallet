// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ui_components/components/icon/lightning_btc_composite_icon.dart';
import 'package:ui_components/gen/assets.gen.dart';
import 'package:ui_components/shared/shared.dart';
import 'package:vector_graphics/vector_graphics.dart';

export 'contextual_glass_icon.dart';
export 'lightning_btc_composite_icon.dart';

const _defaultSize = 24.0;

typedef AquaIconBuilder = AquaIcon Function({
  Color? color,
  Key? key,
  VoidCallback? onTap,
  EdgeInsets? padding,
  double size,
});

enum _DirectionalType { none, forward, back }

class AquaIcon extends StatelessWidget {
  const AquaIcon._({
    required this.asset,
    this.color,
    this.onTap,
    this.padding,
  })  : size = _defaultSize,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;

  AquaIcon.arrowLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowLeft,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowUp({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowUp,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowRight,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowDown({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowDown,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowDownRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowDownRight,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowDownLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowDownLeft,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowUpLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowUpLeft,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.arrowUpRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowUpRight,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.chevronDown({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chevronDown,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.chevronLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chevronLeft,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.chevronUp({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chevronUp,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.chevronRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chevronRight,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.star({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.star,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.starFilled({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.starFilled,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.caret({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.caret,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.check({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.check,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.pending({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.pending,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;

  AquaIcon.notification({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.notification,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.notificationIndicator({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.notificationIndicator,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.eyeOpen({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.eyeOpen,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.eyeClose({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.eyeClose,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.swap({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.swap,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.swapVertical({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.swapVertical,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.scan({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.scan,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.filter({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.filter,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.paste({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.paste,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.danger({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.danger,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.wallet({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.wallet,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.hardwareWallet({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.hardwareWallet,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.aquaIcon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.aquaIcon,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.aquaLogo({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.aquaLogo,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.refresh({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.refresh,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.warning({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.warning,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.marketplace({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.marketplace,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.export({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.export,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.remove({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.remove,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.images({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.images,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.settings({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.settings,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.edit({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.edit,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.externalLink({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.externalLink,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.image({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.image,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.account({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.account,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.fees({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.fees,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.lightbulb({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.lightbulb,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.plus({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.plus,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.close({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.close,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.checkCircle({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.checkCircle,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.logout({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.logout,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.minus({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.minus,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.infoCircle({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.infoCircle,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.more({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.more,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.language({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.language,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.history({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.history,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.share({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.share,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.rotate({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.rotate,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.referenceRate({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.referenceRate,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.spinnerLoading({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.spinnerLoading,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.box({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.box,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.map({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.map,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.theme({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.theme,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.copy({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.copy,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.key({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.key,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.globe({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.globe,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.biometricFingerprint({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.biometricFingerprint,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.pokerchip({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.pokerchip,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.assets({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.assets,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.pegIn({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.pegIn,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.passcode({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.passcode,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.qrIcon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.qrIcon,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.experimental({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.experimental,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.switching({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.switching,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.shield({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.shield,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.helpSupport({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.helpSupport,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.redo({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.redo,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.home({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.home,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.chart({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chart,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.tool({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.tool,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.upload({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.upload,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.user({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.user,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.search({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.search,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.sidebarVisibilityLeft({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.sidebarVisibilityLeft,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.sidebarVisibilityRight({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.sidebarVisibilityRight,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.creditCard({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.creditCard,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.hamburger({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.hamburger,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.grab({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.grab,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.trendUp({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.trendUp,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.statusSuccess({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.statusSuccess,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.statusWarning({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.statusWarning,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.statusDanger({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.statusDanger,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.statusNeutral({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.statusNeutral,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.contextualIcon({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.contextualIcon,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.visa({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    bool colored = false,
    this.size = _defaultSize,
  })  : asset = colored ? AquaUiAssets.svgs.visaColor : AquaUiAssets.svgs.visa,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.lock({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.lock,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.trash({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.trash,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.mastercard({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.mastercard,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.googlePay({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.googlePay,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.applePay({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.applePay,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.sepa({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.sepa,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.btcDirect({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.btcDirect,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.changelly({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.changelly,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.coinbits({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.coinbits,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.selectAll({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.selectAll,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.copyMultiple({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.copyMultiple,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.btcpay({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.btcpay,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.telegram({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.telegram,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.note({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.note,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.web({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.web,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.twitter({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.twitter,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.instagram({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.instagram,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.jan3Logo({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.jan3Logo,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;
  AquaIcon.jan3LogoDark({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.jan3MiniLogoDark,
        _directionalType = _DirectionalType.none,
        _forwardAsset = null,
        _backAsset = null;

  // RTL-aware directional icons
  // These flip automatically based on text direction (LTR vs RTL)
  AquaIcon.chevronForward({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chevronRight,
        _directionalType = _DirectionalType.forward,
        _forwardAsset = AquaUiAssets.svgs.chevronRight,
        _backAsset = AquaUiAssets.svgs.chevronLeft;
  AquaIcon.chevronBack({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.chevronLeft,
        _directionalType = _DirectionalType.back,
        _forwardAsset = AquaUiAssets.svgs.chevronRight,
        _backAsset = AquaUiAssets.svgs.chevronLeft;
  AquaIcon.arrowForward({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowRight,
        _directionalType = _DirectionalType.forward,
        _forwardAsset = AquaUiAssets.svgs.arrowRight,
        _backAsset = AquaUiAssets.svgs.arrowLeft;
  AquaIcon.arrowBack({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  })  : asset = AquaUiAssets.svgs.arrowLeft,
        _directionalType = _DirectionalType.back,
        _forwardAsset = AquaUiAssets.svgs.arrowRight,
        _backAsset = AquaUiAssets.svgs.arrowLeft;

  final SvgGenImage asset;
  final double size;
  final Color? color;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final _DirectionalType _directionalType;
  final SvgGenImage? _forwardAsset;
  final SvgGenImage? _backAsset;

  @override
  Widget build(BuildContext context) {
    // Determine the correct asset based on text direction for RTL-aware icons
    final effectiveAsset = switch (_directionalType) {
      _DirectionalType.forward =>
        Directionality.of(context) == TextDirection.rtl
            ? _backAsset!
            : _forwardAsset!,
      _DirectionalType.back => Directionality.of(context) == TextDirection.rtl
          ? _forwardAsset!
          : _backAsset!,
      _DirectionalType.none => asset,
    };

    return Container(
      alignment: Alignment.center,
      child: InkWell(
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call())
            : null,
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
          child: effectiveAsset.svg(
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

/// Loads an SVG from [url] using [VectorGraphic] so that [errorBuilder] is
/// available. [SvgPicture.network] does not expose [errorBuilder]; the
/// underlying [VectorGraphic] widget does.
class _NetworkSvgFallback extends StatelessWidget {
  const _NetworkSvgFallback({required this.url, required this.fallback});

  final String url;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return VectorGraphic(
      loader: SvgNetworkLoader(url),
      fit: BoxFit.contain,
      placeholderBuilder: (_) => const SizedBox.shrink(),
      errorBuilder: (_, __, ___) => fallback,
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
        AssetIds.layer2 => AquaAssetIcon.l2Bitcoin(
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
        _ when (AssetIds.mexas.contains(assetId)) => AquaAssetIcon.mexas(
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
  AquaAssetIcon.lightningBtcComposite({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = LightningBtcCompositeIcon(size: size);
  AquaAssetIcon.mexas({
    super.key,
    this.color,
    this.onTap,
    this.padding,
    this.size = _defaultSize,
  }) : icon = AquaUiAssets.svgs.currency.mexas.svg();
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
  }) : icon = _NetworkSvgFallback(
          url: url,
          fallback: AquaUiAssets.svgs.currency.assetUnknown.svg(),
        );

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
        onTap: onTap != null
            ? () => WidgetsBinding.instance
                .addPostFrameCallback((_) => onTap?.call())
            : null,
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
