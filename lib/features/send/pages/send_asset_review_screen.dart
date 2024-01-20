import 'package:aqua/common/errors/error_localized.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/external/boltz/boltz_provider.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../providers/send_asset_fee_provider.dart';

extension BoltzSendAssetReviewExtension on SendAssetReviewScreen {
  Future<void> boltzCreateOnchainTransaction(
      BuildContext context, WidgetRef ref) async {
    // get current order
    final boltzCurrentOrder =
        ref.watch(boltzSwapSuccessResponseProvider.notifier).state;

    if (boltzCurrentOrder != null) {
      // watch boltz order status
      final _ =
          ref.read(boltzProvider).getSwapStatusStream(boltzCurrentOrder.id);

      // create tx
      final gdkTransaction = await ref
          .read(boltzProvider)
          .createOnchainNormalSwap(createSwapResponse: boltzCurrentOrder);
      logger.d('[Send][Boltz] createGdkTransaction response: $gdkTransaction}');
    }
  }
}

extension SideShiftSendAssetReviewExtension on SendAssetReviewScreen {
  Future<void> sideshiftCreateOnchainTransaction(
      BuildContext context, WidgetRef ref) async {
    final asset = ref.read(sendAssetProvider);

    // get order
    final pendingOrder = ref.read(pendingOrderProvider);
    if (pendingOrder == null) {
      throw Exception('[Send][Sideshift] No pending order found');
    }

    logger.d(
        '[Send][Sideshift] send review screen - pendingOrder found: ${pendingOrder.id}}');

    // create tx
    final gdkTransaction = await ref
        .read(sideshiftOrderProvider)
        .createLiquidTransaction(
            pendingOrder: pendingOrder, receiveAsset: asset);
    logger
        .d('[Send][Sideshift] createGdkTransaction response: $gdkTransaction}');
  }
}

extension TaxiSendAssetExtension on SendAssetReviewScreen {
  Future<void> createAndSignPsbtTransaction(
      BuildContext context, WidgetRef ref, SendAssetArguments arguments) async {
    final asset = ref.read(sendAssetProvider);
    final amountSatoshi = ref.read(formatterProvider).parseAssetAmountDirect(
        amount: arguments.userEnteredAmount.toString(),
        precision: asset.precision);
    final address = arguments.address;

    final gdkPsetTransaction = await ref
        .read(sendAssetTransactionProvider.notifier)
        .createAndSignTaxiPsbt(
            amount: amountSatoshi, address: address, asset: asset);

    logger
        .d('[Send][Taxi] create and sign pset  response: $gdkPsetTransaction}');
  }
}

extension OnchainSendAssetExtension on SendAssetReviewScreen {
  Future<void> createOnchainTransaction(
    BuildContext context,
    WidgetRef ref,
    SendAssetArguments arguments,
  ) async {
    logger.d(
        '[Send] feeRateNotifier value ${ref.read(feeInSatsProvider).toInt()}');
    final asset = ref.read(sendAssetProvider);

    try {
      final network = asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;

      final feeRatePerKb = network == NetworkType.bitcoin
          ? ref.watch(selectedFeeRatePerKByteProvider)?.toInt()
          : liquidFeeRate;

      if (feeRatePerKb == null) {
        return;
      }

      final useAllFunds = ref.watch(useAllFundsProvider);
      final amountSatoshi = ref.read(formatterProvider).parseAssetAmountDirect(
          amount: arguments.userEnteredAmount.toString(),
          precision: asset.precision);

      logger.d(
          '[Send][Fee] creating transaction with fee rate per kb: $feeRatePerKb');
      logger.d('[Send] creating transaction with useAllFunds: $useAllFunds');

      final gdkTransaction = await ref
          .read(sendAssetTransactionProvider.notifier)
          .createTransaction(
            amountSatoshi: amountSatoshi,
            assetId: asset.id,
            sendAll: useAllFunds,
            address: arguments.address,
            feeRate: feeRatePerKb,
            network: network,
          );

      logger.d('[Send] GDK TX: $gdkTransaction');
      logger.d('[Send] createGdkTransaction response: $gdkTransaction}');
      logger.d(
          '[Send][Fee] feeInSatsProvider: ${ref.read(feeInSatsProvider).toInt()}');
      ref.read(insufficientBalanceProvider.notifier).state = false;
    } on GdkNetworkInsufficientFunds {
      ref.read(insufficientBalanceProvider.notifier).state = true;
    }
  }

  Future<void> sendOnchainTransaction(
      WidgetRef ref, NetworkType network, Function pushToCompleteScreen) async {
    final asset = ref.read(sendAssetProvider);
    final gdkTransaction =
        ref.watch(sendAssetTransactionProvider).asData?.value;

    if (gdkTransaction != null) {
      final gdkSignedTransaction = await ref
          .read(sendAssetTransactionProvider.notifier)
          .signTransaction(transaction: gdkTransaction, network: network);

      if (gdkSignedTransaction != null) {
        logger.d('[Send] signed transaction: $gdkSignedTransaction');

        final txId = await ref
            .read(sendAssetTransactionProvider.notifier)
            .broadcastTransaction(
                rawTx: gdkSignedTransaction.transaction!,
                network: network,
                broadcastType: asset.broadcastService);

        if (txId != null) {
          logger.d('[Send] txId: $txId');

          // success
          ref
              .read(sendAssetTransactionProvider.notifier)
              .success(gdkSignedTransaction);

          pushToCompleteScreen(txId, gdkTransaction.timestamp, network);
        }
      }
    }
  }
}

class SendAssetReviewScreen extends HookConsumerWidget {
  const SendAssetReviewScreen({super.key});

  static const routeName = '/sendAssetReviewScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as SendAssetArguments;
    final network =
        arguments.asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;

    // setup
    final feeRates = ref.watch(feeRatesPerVByteProvider(network)).asData?.value;
    final fee = ref.watch(estimatedFeeProvider);
    final feeAsset = ref.watch(selectedFeeAssetProvider);
    final insufficientBalance = ref.watch(insufficientBalanceProvider);
    final gdkTx = ref.watch(sendAssetTransactionProvider).asData?.value;

    // ui
    final feeToDisplay = ref.watch(feeToDisplayProvider(arguments.asset));
    final note = ref.watch(noteProvider);

    // show a modal telling the user they don't have enough funds
    useEffect(() {
      if (insufficientBalance) {
        Future.microtask(() => showModalBottomSheet(
              context: context,
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              builder: (_) => InsufficientBalanceSheet(
                asset:
                    SendAssetArguments.fromAsset(ref.read(sendAssetProvider)),
              ),
            ));
      }
      return null;
    }, [insufficientBalance]);

    // push to complete screen
    void pushToCompleteScreen(String txId, int timestamp, NetworkType network) {
      if (arguments.asset.isLightning) {
        final amountSatoshi =
            ref.read(formatterProvider).parseAssetAmountDirect(
                  amount: arguments.userEnteredAmount.toString(),
                  precision: arguments.asset.precision,
                );

        Navigator.of(context)
          ..popUntil((r) => r.isFirst)
          ..pushNamed(
            LightningTransactionSuccessScreen.routeName,
            arguments: LightningSuccessArguments.send(
              satoshiAmount: amountSatoshi,
            ),
          );
      } else {
        Navigator.of(context)
          ..popUntil((r) => r.isFirst)
          ..pushNamed(
            SendAssetTransactionCompleteScreen.routeName,
            arguments: arguments.copyWith(
              note: note,
              network: network == NetworkType.bitcoin ? 'Bitcoin' : 'Liquid',
              timestamp: timestamp,
              transactionId: txId,
            ),
          );
      }
    }

    // on confirm swipe
    final onTransactionConfirm = useCallback(() {
      final network =
          arguments.asset.isBTC ? NetworkType.bitcoin : NetworkType.liquid;
      sendOnchainTransaction(ref, network, pushToCompleteScreen);
    }, [fee, note]);

    // create initial tx
    final createTransaction = useCallback(() {
      if (arguments.asset.isLightning) {
        boltzCreateOnchainTransaction(context, ref);
      } else if (arguments.asset.isSideshift) {
        sideshiftCreateOnchainTransaction(context, ref);
      } else if (feeAsset == FeeAsset.tetherUsdt) {
        createAndSignPsbtTransaction(context, ref, arguments);
      } else {
        createOnchainTransaction(context, ref, arguments);
      }
    }, []);

    ref.listen(feeRatesPerVByteProvider(network), (_, feeRates) {
      if (feeRates is AsyncData || feeRates is AsyncError) {
        createTransaction();
      }
    });

    ref.listen(selectedFeeAssetProvider, (_, __) {
      createTransaction();
    });

    ref.listen(selectedFeeRatePerKByteProvider, (_, __) {
      createTransaction();
    });

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        title: AppLocalizations.of(context)!.sendAssetScreenTitle,
        backgroundColor: Theme.of(context).colors.altScreenBackground,
        iconBackgroundColor: Theme.of(context).colors.altScreenSurface,
      ),
      backgroundColor: Theme.of(context).colors.altScreenBackground,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
        child: Column(
          children: [
            //ANCHOR - Send Review Card
            //Sideshift
            if (arguments.asset.isSideshift) ...[
              Text(
                AppLocalizations.of(context)!.sendAssetReviewScreenGenericLabel(
                    arguments.network, arguments.symbol),
              ),
              SizedBox(height: 20.h),
            ],
            //All other assets
            SendAssetReviewInfoCard(arguments: arguments),
            SizedBox(height: 22.h),
            //ANCHOR - Fee Cards
            // Bitcoin
            if (arguments.asset.isBTC) ...{
              if (gdkTx != null && feeRates != null)
                TransactionPrioritySelector(
                    gdkTransaction: gdkTx,
                    onFeeRateChange: (feeRate) {
                      ref.read(selectedFeeRatePerKByteProvider.notifier).state =
                          feeRate;
                    },
                    rates: feeRates),
              SizedBox(
                height: 10.h,
              ),
            }
            // Sideshift (usdt-eth & trx) or Boltz (lighting)
            else if (arguments.asset.isSideshift ||
                arguments.asset.isLightning) ...{
              if (gdkTx != null && feeToDisplay != null)
                GenericAssetTransactionFeeCard(
                  arguments: arguments,
                ),
            }
            // All Liquid Assets
            else ...{
              UsdtTransactionFeeSelector(
                  asset: arguments.asset, gdkTransaction: gdkTx),
            },
            SizedBox(height: 10.h),
            const Spacer(),
            //ANCHOR - Confirmation Slider or Error
            Consumer(
              builder: (context, ref, child) {
                return ref.watch(sendAssetTransactionProvider).when(
                      data: (_) {
                        return SendAssetConfirmSlider(
                          text: insufficientBalance
                              ? AppLocalizations.of(context)!
                                  .sendAssetAmountScreenNotEnoughFundsError
                              : AppLocalizations.of(context)!
                                  .sendAssetReviewScreenConfirmSlider,
                          enabled: !insufficientBalance && (gdkTx != null),
                          onConfirm: onTransactionConfirm,
                        );
                      },
                      loading: () => const CircularProgressIndicator(),
                      error: (error, _) {
                        final String errorMessage;
                        if (error is ErrorLocalized) {
                          errorMessage = error.toLocalizedString(context);
                        } else {
                          errorMessage = error.toString();
                        }

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            CustomError(errorMessage: errorMessage),
                            const SizedBox(height: 40.0),
                          ],
                        );
                      },
                    );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class TransactionDetails extends HookConsumerWidget {
  const TransactionDetails({
    super.key,
    required this.arguments,
    required this.amount,
    required this.fee,
    required this.total,
  });

  final SendAssetArguments arguments;
  final String? amount;
  final String? fee;
  final String? total;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeUnit = arguments.network == 'Liquid' ? 'L-BTC' : 'BTC';
    return Row(children: [
      Expanded(
          flex: 1,
          child: BoxShadowCard(
              color: Theme.of(context).colors.altScreenSurface,
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                            AppLocalizations.of(context)!
                                .sendAssetReviewScreenSendTo),
                        Text(arguments.address)
                      ],
                    ),
                    SizedBox(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 15.h,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                  AppLocalizations.of(context)!
                                      .sendAssetReviewScreenAmount),
                              Text("${amount!} ${arguments.asset.ticker}")
                            ],
                          ),
                          SizedBox(
                            height: 5.h,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                  AppLocalizations.of(context)!
                                      .sendAssetReviewScreenFee),
                              Text("${fee!} $feeUnit")
                            ],
                          ),
                          SizedBox(
                            height: 3.h,
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              )))
    ]);
  }
}
