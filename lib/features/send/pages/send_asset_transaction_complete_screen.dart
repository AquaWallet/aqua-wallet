import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/constants.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lottie/lottie.dart';

class SendAssetTransactionCompleteScreen extends HookConsumerWidget {
  const SendAssetTransactionCompleteScreen({
    super.key,
    required this.args,
  });

  static const routeName = '/sendAssetTransactionCompleteScreen';

  final SendAssetCompletionArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
    final asset = args.asset;

    final onDone = useCallback(() {
      if (args.transactionType == SendTransactionType.topUp) {
        context.popUntilPath(DebitCardMyCardScreen.routeName);
        context.showSuccessSnackbar(context.loc.yourTopUpIsBeingProcessed);
      } else {
        context.go(AuthWrapper.routeName);
      }
    }, [args.transactionType]);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13,
        onBackPressed: onDone,
        onActionButtonPressed: onDone,
        title: args.transactionType == SendTransactionType.topUp
            ? context.loc.topUp
            : context.loc.send,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, viewportConstraints) => SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            height: context.adaptiveDouble(
                              smallMobile: 5,
                              mobile: 18,
                            ),
                          ),
                          //ANCHOR - Checkmark Animation
                          Lottie.asset(
                            botevMode ? animation.tickBotev : animation.tick,
                            repeat: false,
                            width: context.adaptiveDouble(
                              smallMobile: 100,
                              mobile: 140,
                              tablet: 140,
                            ),
                            height: context.adaptiveDouble(
                              smallMobile: 100,
                              mobile: 140,
                              tablet: 140,
                            ),
                            fit: BoxFit.contain,
                          ),
                          switch (args.transactionType) {
                            SendTransactionType.send =>
                              _SendTransactionAmountDetails(args: args),
                            SendTransactionType.topUp =>
                              _TopUpTransactionAmountDetails(args: args),
                            SendTransactionType.privateKeySweep =>
                              _PrivateKeySweepTransactionAmountDetails(
                                  args: args),
                          },
                          const SizedBox(height: 28),
                          if (asset.isLightning) ...{
                            //ANCHOR - Lightning Fee
                            TransactionFeeBreakdownCard(
                              args: FeeStructureArguments.aquaSend(
                                sendAssetArgs:
                                    SendAssetArguments.fromAsset(asset),
                              ),
                            ),
                          } else if (asset.isAltUsdt) ...{
                            //ANCHOR - USDt Swap Fee
                            TransactionFeeBreakdownCard(
                              args: FeeStructureArguments.usdtSwap(
                                sendAssetArgs:
                                    SendAssetArguments.fromAsset(asset),
                              ),
                            ),
                          } else if (args.transactionType ==
                              SendTransactionType.topUp) ...{
                            TopUpTransactionInfoCard(
                              arguments: args,
                            )
                          } else ...{
                            //ANCHOR - Transaction Info
                            TransactionInfoCard(
                              arguments: args,
                            )
                          },
                          const SizedBox(height: 20),
                          //ANCHOR - Transaction ID
                          TransactionIdCard(arguments: args),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        //ANCHOR - Button
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width: double.maxFinite,
                          child: BoxShadowElevatedButton(
                            onPressed: onDone,
                            child: Text(
                              context.loc.done,
                            ),
                          ),
                        ),
                        const SizedBox(height: kBottomPadding),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendTransactionAmountDetails extends HookConsumerWidget {
  const _SendTransactionAmountDetails({
    required this.args,
  });

  final SendAssetCompletionArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayUnit = ref.watch(
        displayUnitsProvider.select((p) => p.getForcedDisplayUnit(args.asset)));

    final cryptoAmountInSats = useMemoized(() {
      return args.amountSats ??
          ref.read(formatterProvider).parseAssetAmountDirect(
                amount: args.amountFiat ?? '0',
                precision: args.asset.precision,
              );
    }, [args.amountFiat]);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //ANCHOR - Amount Title
        Text(
          context.loc.youveSuccessfullySent,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w500,
            height: 1.50,
          ),
        ),
        const SizedBox(height: 6),
        //ANCHOR - Amount
        AssetCryptoAmount(
          forceVisible: true,
          forceDisplayUnit: displayUnit,
          amount: cryptoAmountInSats.toString(),
          asset: args.asset,
          showUnit: true,
          style: const TextStyle(
            fontSize: 32,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _TopUpTransactionAmountDetails extends HookConsumerWidget {
  const _TopUpTransactionAmountDetails({
    required this.args,
  });
  final SendAssetCompletionArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayUnit = ref.watch(
      displayUnitsProvider.select((p) => p.getForcedDisplayUnit(args.asset)),
    );
    final amount = (Decimal.fromInt(args.amountSats ?? 0) /
            DecimalExt.fromAssetPrecision(args.asset.precision))
        .toDouble();
    final fiatAmount =
        ref.read(moonBtcPriceProvider.notifier).getSatsToFiatDisplay(
              args.amountSats ?? 0,
            );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //ANCHOR - Amount Title
        Text(
          context.loc.yourTopUpWasSuccessful,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: UiFontFamily.helveticaNeue,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        //ANCHOR - USD Amount
        Text(
          args.asset.isAnyUsdt
              ? '\$${amount.toStringAsFixed(2)}'
              : '\$$fiatAmount',
          style: const TextStyle(
            fontSize: 32,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!args.asset.isAnyUsdt) ...{
          //ANCHOR - Crypto Amount
          AssetCryptoAmount(
            forceVisible: true,
            forceDisplayUnit: displayUnit,
            amount: args.amountSats.toString(),
            asset: args.asset,
            style: TextStyle(
              color: context.colors.topUpTransactionAmountSubtitleColor,
              fontSize: 14,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w500,
            ),
            unitStyle: TextStyle(
              color: context.colors.topUpTransactionAmountSubtitleColor,
              fontSize: 14,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w500,
            ),
          ),
        },
      ],
    );
  }
}

class _PrivateKeySweepTransactionAmountDetails extends HookConsumerWidget {
  const _PrivateKeySweepTransactionAmountDetails({
    required this.args,
  });

  final SendAssetCompletionArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayUnit = ref.watch(
      displayUnitsProvider.select((p) => p.getForcedDisplayUnit(args.asset)),
    );
    final amount = (Decimal.fromInt(args.amountSats ?? 0) /
            DecimalExt.fromAssetPrecision(args.asset.precision))
        .toDouble();
    final fiatAmount = useFuture(ref.read(fiatProvider).getSatsToFiatDisplay(
          args.amountSats ?? 0,
          false,
        ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        //ANCHOR - Amount Title
        Text(
          context.loc.pokerChipSweepSuccessful,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: UiFontFamily.helveticaNeue,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 6),
        //ANCHOR - USD Amount
        Text(
          args.asset.isAnyUsdt
              ? '\$${amount.toStringAsFixed(2)}'
              : '\$${fiatAmount.data ?? '0'}',
          style: const TextStyle(
            fontSize: 32,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (!args.asset.isAnyUsdt) ...{
          //ANCHOR - Crypto Amount
          AssetCryptoAmount(
            forceVisible: true,
            forceDisplayUnit: displayUnit,
            amount: args.amountSats.toString(),
            asset: args.asset,
            style: TextStyle(
              color: context.colors.topUpTransactionAmountSubtitleColor,
              fontSize: 14,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w500,
            ),
            unitStyle: TextStyle(
              color: context.colors.topUpTransactionAmountSubtitleColor,
              fontSize: 14,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w500,
            ),
          ),
        },
      ],
    );
  }
}
