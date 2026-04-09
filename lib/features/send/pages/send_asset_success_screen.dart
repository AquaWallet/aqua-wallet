import 'package:aqua/config/config.dart' hide AquaColors;
import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/home/pages/pages.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';
import 'package:ui_components/ui_components.dart';

const _lightningTotalFrames = 251.0;
const _lightningLoopStartFrame = 84.0;
const _lightningLogoFadeInFrame = 38.0;
const _waveTotalFrames = 250.0;
const _waveLoopStartFrame = 100.0;
const _waveLogoFadeInFrame = 65.0;

class AssetTransactionSuccessScreen extends HookConsumerWidget {
  const AssetTransactionSuccessScreen({super.key, required this.args});

  final TransactionSuccessArguments args;

  static const routeName = '/assetSuccess';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liquid = ref.watch(liquidProvider);
    final assetForTransactions =
        args.asset.isLightning ? Asset.lbtc() : args.asset;
    final uiModels =
        ref.watch(transactionsProvider(assetForTransactions)).valueOrNull;
    final isLightningReceive = args.asset.isLightning && args.isReceive;

    final transactionId = useMemoized(() {
      if (isLightningReceive) {
        final lightningReceiveTransaction = ref
            .read(transactionsProvider(assetForTransactions).notifier)
            .findLightningTransactionWithBoltzOrder(args.serviceOrderId);

        return lightningReceiveTransaction?.mapOrNull(
          normal: (model) => model.transaction.txhash,
          pending: (model) => model.dbTransaction?.txhash,
        );
      }

      return args.txId;
    }, [args.txId, uiModels]);

    final formattedAmountWithUnit = useMemoized(
      () {
        final unit = ref.read(displayUnitsProvider).currentDisplayUnit;
        final fmtAmount = ref.read(formatProvider).formatAssetAmount(
              amount: args.amountToReceive ?? 0,
              asset: args.asset,
              displayUnitOverride: unit,
              decimalPlacesOverride:
                  args.asset.isAnyUsdt ? kUsdtDisplayPrecision : null,
            );
        final assetTicker = args.asset.getDisplayTicker(unit);
        return '$fmtAmount $assetTicker';
      },
      [args],
    );

    final hasAnimation = args.asset.hasSuccessAnimation(liquid);
    final showUI = useState(!hasAnimation);
    final animController = useAnimationController();
    final loopStartRatio = args.asset.isLightning
        ? _lightningLoopStartFrame / _lightningTotalFrames
        : _waveLoopStartFrame / _waveTotalFrames;
    final logoFadeInRatio = args.asset.isLightning
        ? _lightningLogoFadeInFrame / _lightningTotalFrames
        : _waveLogoFadeInFrame / _waveTotalFrames;

    useEffect(() {
      void valueListener() {
        if (!showUI.value && animController.value >= logoFadeInRatio) {
          showUI.value = true;
        }
      }

      void statusListener(AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          animController.value = loopStartRatio;
          animController.forward();
        }
      }

      animController.addListener(valueListener);
      animController.addStatusListener(statusListener);
      return () {
        animController.removeListener(valueListener);
        animController.removeStatusListener(statusListener);
      };
    }, [animController]);

    final onDone = useCallback(() {
      if (args.transactionType == SendTransactionType.topUp) {
        context.popUntilPath(DebitCardMyCardScreen.routeName);
        context.showSuccessSnackbar(context.loc.yourTopUpIsBeingProcessed);
      } else {
        context.popUntilPath(HomeScreen.routeName);
        context.push(AssetTransactionsScreen.routeName,
            extra: args.asset.redirectAsset);
      }
    }, [args.transactionType]);

    return Theme(
      data: ref.watch(newLightThemeProvider(context)),
      child: Scaffold(
        backgroundColor: AquaPrimitiveColors.aquaBlue300,
        body: Stack(
          children: [
            if (hasAnimation)
              SizedBox.expand(
                child: Lottie.asset(
                  args.asset.successAnimation(liquid),
                  controller: animController,
                  fit: BoxFit.cover,
                  onLoaded: (composition) {
                    animController.duration = composition.duration;
                    animController.forward();
                  },
                ),
              ),
            IgnorePointer(
              ignoring: !showUI.value,
              child: AnimatedOpacity(
                opacity: showUI.value ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 600),
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        //ANCHOR - Close Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: AquaContextualGlassIcon(
                            onTap: onDone,
                            icon: AquaIcon.close(
                              color: AquaPrimitiveColors.aquaBlue,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        //ANCHOR - Content
                        Expanded(
                          child: Column(
                            mainAxisAlignment: hasAnimation
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.center,
                            children: [
                              if (!hasAnimation)
                                AquaIcon.aquaLogo(
                                  size: 32,
                                  color: AquaPrimitiveColors.palatinateBlue750,
                                ),
                              //ANCHOR - Asset Icon Illustration
                              if (!hasAnimation)
                                SizedBox.square(
                                  dimension: 240,
                                  child: switch (args.asset) {
                                    _ when (args.asset.isBTC) => UiAssets
                                        .svgs.successIllustrations.btc
                                        .svg(),
                                    _ when (args.asset.id == liquid.depixId) =>
                                      UiAssets.svgs.successIllustrations.depix
                                          .svg(),
                                    _ when (args.asset.id == liquid.mexasId) =>
                                      UiAssets.svgs.successIllustrations.mexas
                                          .svg(),
                                    _ when (args.asset.id == liquid.eurXId) =>
                                      UiAssets.svgs.successIllustrations.eurx
                                          .svg(),
                                    _ => (args.asset.isUnknown ||
                                            args.asset.logoUrl.isEmpty)
                                        ? const SizedBox.shrink()
                                        : AssetIcon(
                                            assetLogoUrl: args.asset.logoUrl,
                                            assetId: args.asset.id,
                                            size: 240,
                                          ),
                                  },
                                ),
                              //ANCHOR - Label
                              AquaText.body1Medium(
                                text: args.asset.isLightning
                                    ? (args.isReceive
                                        ? context.loc.receiving
                                        : context.loc.youAreSending)
                                    : context.loc
                                        .sendAssetReviewScreenConfirmAmountTitleSent,
                                color: AquaColors.darkColors.textPrimary,
                              ),
                              const SizedBox(height: 8),
                              //ANCHOR - Amount
                              AquaText.h3SemiBold(
                                text: formattedAmountWithUnit,
                                color: AquaColors.darkColors.textPrimary,
                              ),
                              if (hasAnimation) const SizedBox(height: 32),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        //ANCHOR - Done Button
                        SizedBox(
                          width: double.maxFinite,
                          child: AquaButton.primary(
                            onPressed: onDone,
                            isInverted: true,
                            text: context.loc.commonGotIt,
                          ),
                        ),
                        const SizedBox(height: 16),
                        //ANCHOR - View Receipt Button
                        SizedBox(
                          width: double.maxFinite,
                          child: AquaButton.tertiary(
                            isLoading:
                                isLightningReceive && transactionId == null,
                            onPressed: transactionId != null
                                ? () => context
                                  ..popUntilPath(HomeScreen.routeName)
                                  ..push(
                                    AssetTransactionDetailsScreen.routeName,
                                    extra: TransactionDetailsArgs(
                                      asset: args.asset,
                                      transactionId: transactionId,
                                    ),
                                  )
                                : null,
                            isInverted: true,
                            text: context.loc.commonSwapViewReceipt,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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
