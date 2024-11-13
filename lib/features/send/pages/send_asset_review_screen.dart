import 'dart:async';

import 'package:aqua/common/dialogs/dialog_manager.dart';
import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/common/widgets/custom_alert_dialog/custom_alert_dialog_ui_model.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/electrs_provider.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/providers/sideshift_send_provider.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final _debouncer = Debouncer(milliseconds: 300);

class SendAssetReviewScreen extends HookConsumerWidget {
  const SendAssetReviewScreen({super.key, this.arguments});

  static const routeName = '/sendAssetReviewScreen';

  final SendAssetArguments? arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sliderState = useState(SliderState.initial);

    final asset = ref.watch(sendAssetProvider);
    final transactionDetails = ref.watch(sendAssetSetupProvider);
    final amountDisplay = ref.watch(amountMinusFeesToDisplayProvider) ??
        arguments?.userEnteredAmount.toString() ??
        '-';

    // fees
    final insufficientBalance = ref.watch(insufficientBalanceProvider);

    // taxi errors
    ref.listen(
        sideswapTaxiProvider,
        (_, state) => state.maybeWhen(
              error: (error, stackTrace) async {
                sliderState.value = SliderState.initial;

                final alertModel = CustomAlertDialogUiModel(
                    title: context.loc.taxiFeeErrorTitle,
                    subtitle: context.loc.taxiFeeErrorSubtitle(error),
                    buttonTitle: context.loc.ok,
                    onButtonPressed: () {
                      Navigator.of(context).pop();
                    });
                DialogManager().showDialog(context, alertModel);
              },
              orElse: () => {},
            ));

    final transaction = ref.watch(sendAssetTransactionProvider).asData?.value;
    final isSendAll = ref.read(useAllFundsProvider);

    // ui
    final feeToDisplay = ref.watch(totalFeeToDisplayProvider(asset));
    final addNoteEnabled =
        ref.watch(featureFlagsProvider.select((p) => p.addNoteEnabled));

    // show a modal telling the user they don't have enough funds
    useEffect(() {
      if (insufficientBalance != null) {
        Future.microtask(() => showModalBottomSheet(
              context: context,
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
                ),
              ),
              constraints: BoxConstraints(
                maxHeight: context.adaptiveDouble(
                  mobile: 0.4.sh,
                  tablet: 0.2.sh,
                ),
              ),
              builder: (_) => const InsufficientBalanceSheet(),
            ));
      }
      return null;
    }, [insufficientBalance]);

    // completion screen
    void pushToCompleteScreen(String txId, int timestamp, NetworkType network) {
      sliderState.value = SliderState.completed;

      if (asset.isLightning) {
        final boltzOrderId = ref.read(boltzSubmarineSwapProvider)!.id;

        final amountSatoshi =
            ref.read(formatterProvider).parseAssetAmountDirect(
                  amount: ref.read(userEnteredAmountProvider).toString(),
                  precision: asset.precision,
                );

        Navigator.of(context)
          ..popUntil((r) => r.isFirst)
          ..pushNamed(
            LightningTransactionSuccessScreen.routeName,
            arguments: LightningSuccessArguments(
                satoshiAmount: amountSatoshi,
                orderId: boltzOrderId,
                type: LightningSuccessType.send),
          );
      } else {
        Navigator.of(context).pushNamed(
          SendAssetTransactionCompleteScreen.routeName,
          arguments:
              SendAssetCompletionArguments(timestamp: timestamp, txId: txId),
        );
      }
    }

    // on confirm, create and send tx
    final onTransactionConfirm = useCallback(() async {
      sliderState.value = SliderState.inProgress;

      await ref
          .read(sendAssetTransactionProvider.notifier)
          .createAndSendFinalTransaction(onSuccess: pushToCompleteScreen);
    }, []);

    // create initial tx (for now only need plain btc and lbtc for estimates)
    final createInitialTransaction = useCallback(() {
      ref
          .read(sendAssetTransactionProvider.notifier)
          .createInitialGdkTransactionForFeeEstimate();
    }, []);

    // listen to setup
    ref.listen(sendAssetSetupProvider, (_, setup) {
      if (setup.asData?.value == true) {
        createInitialTransaction();
      }
    });

    // listen to user changes
    ref.listen(userSelectedFeeAssetProvider, (_, __) {
      _debouncer.run(() {
        createInitialTransaction();
      });
    });

    ref.listen(userSelectedFeeRatePerVByteProvider, (_, __) {
      _debouncer.run(() {
        createInitialTransaction();
      });
    });

    ref.listen(customFeeInputProvider, (_, __) {
      _debouncer.run(() {
        createInitialTransaction();
      });
    });

    // send tx errors
    ref.listen(
        sendAssetTransactionProvider,
        (_, state) => state.maybeWhen(
              error: (error, stackTrace) async {
                sliderState.value = SliderState.initial;

                final String errorMessage;
                if (error is MempoolConflictTxBroadcastException) {
                  // if mempool conflict broadcast error, show message prompting to retry in ~60 seconds
                  // this error occurs because lowball txs don't appear in the mempool, so if a user tries to send a second lowball tx before the first one is mined,
                  // gdk will double spend the utxos.
                  MempoolConflictDialog.show(context, onRetry: () {
                    ref
                        .read(sendAssetTransactionProvider.notifier)
                        .createAndSendFinalTransaction(
                          onSuccess: pushToCompleteScreen,
                          isLowball: true,
                        );
                  }, onCancel: () {});
                  return;
                }
                if (error is AquaTxBroadcastException) {
                  // will happen if our lowball node is down, or if there is any other tx broadcast error
                  final alertModel = CustomAlertDialogUiModel(
                    title: context.loc.broadcastTxExceptionTitle,
                    subtitle: context.loc.aquaBroadcastTxExceptionMessage,
                    buttonTitle: context.loc.cancel,
                    secondaryButtonTitle: context.loc.tryAgain,
                    onButtonPressed: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    onSecondaryButtonPressed: () {
                      Navigator.of(context).pop();
                      ref
                          .read(sendAssetTransactionProvider.notifier)
                          .createAndSendFinalTransaction(
                            onSuccess: pushToCompleteScreen,
                            isLowball: false,
                          );
                    },
                  );
                  await showCustomAlertDialog(
                      context: context, uiModel: alertModel);
                  return;
                } else if (error is ExceptionLocalized) {
                  errorMessage = error.toLocalizedString(context);
                } else if (error is NetworkException) {
                  errorMessage = error.message != null
                      ? context.loc.networkErrorSpecific(error.message!)
                      : context.loc.networkErrorGeneric;
                } else {
                  errorMessage = error.toString();
                }

                final alertModel = CustomAlertDialogUiModel(
                    title: context.loc.genericErrorMessage,
                    subtitle: errorMessage,
                    buttonTitle: context.loc.ok,
                    onButtonPressed: () {
                      Navigator.of(context).pop();
                    });
                DialogManager().showDialog(context, alertModel);
              },
              orElse: () => {},
            ));

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        logger.d('[Navigation] onPopInvoked in SendAssetScreen called');
        ref.read(sideshiftSendProvider).stopAllStreams();
      },
      child: Scaffold(
        appBar: AquaAppBar(
          showActionButton: false,
          title: context.loc.sendAssetScreenTitle,
          backgroundColor: Theme.of(context).colors.altScreenBackground,
          iconBackgroundColor: Theme.of(context).colors.altScreenSurface,
        ),
        //ANCHOR - Confirmation Slider
        floatingActionButton: transactionDetails.mapOrNull(
          data: (_) => SendAssetConfirmSlider(
            text: insufficientBalance != null
                ? context.loc.sendAssetAmountScreenNotEnoughFundsError
                : context.loc.sendAssetReviewScreenConfirmSlider,
            enabled: insufficientBalance == null,
            onConfirm: onTransactionConfirm,
            sliderState: sliderState.value,
          ),
        ),
        backgroundColor: Theme.of(context).colors.altScreenBackground,
        body: transactionDetails.map(
          data: (_) => Stack(
            children: [
              SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.only(
                  left: 28.w,
                  right: 28.w,
                  top: 32.h,
                  bottom: 140.h,
                ),
                child: Column(
                  children: [
                    //ANCHOR - Send Review Card
                    //Sideshift
                    if (asset.isSideshift) ...[
                      Text(
                        context.loc.sendAssetReviewScreenGenericLabel(
                          asset.network,
                          asset.symbol,
                        ),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(height: 20.h),
                    ],
                    //All other assets
                    SendAssetReviewInfoCard(
                      amountDisplay: amountDisplay,
                    ),
                    SizedBox(height: 22.h),
                    //ANCHOR - Fee Cards
                    // Bitcoin
                    if (asset.isBTC) ...{
                      if (transaction != null) ...{
                        TransactionPrioritySelector(transaction: transaction),
                      },
                      SizedBox(height: 10.h),
                    }
                    // Sideshift (usdt-eth & trx)
                    else if (asset.isSideshift) ...{
                      if (feeToDisplay != null) ...{
                        const GenericAssetTransactionFeeCard(),
                      },
                      LiquidTransactionFeeSelector(
                        asset: asset,
                        transaction: transaction,
                        isSendAll: isSendAll,
                      ),
                    }
                    // Lightning
                    else if (asset.isLightning) ...{
                      if (feeToDisplay != null)
                        const GenericAssetTransactionFeeCard(),
                    }
                    // All Liquid Assets
                    else ...{
                      LiquidTransactionFeeSelector(
                        asset: asset,
                        transaction: transaction,
                        isSendAll: isSendAll,
                      ),
                    },
                    SizedBox(height: 10.h),
                    //ANCHOR - Add Note
                    if (addNoteEnabled) ...{
                      const AddNoteButton(),
                    },
                  ],
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: MediaQuery.sizeOf(context).height * .25,
                  decoration: BoxDecoration(
                    gradient: Theme.of(context).getFadeGradient(),
                  ),
                ),
              ),
            ],
          ),
          error: (asyncError) {
            final error = asyncError.error;
            final String errorMessage;
            if (error is ExceptionLocalized) {
              errorMessage = error.toLocalizedString(context);
            } else {
              errorMessage = error.toString();
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              final alertModel = CustomAlertDialogUiModel(
                title: context.loc.genericErrorMessage,
                subtitle: errorMessage,
                buttonTitle: context.loc.ok,
                onButtonPressed: () {
                  Navigator.of(context).pop();
                },
              );
              DialogManager().showDialog(context, alertModel);
            });

            return Container();
          },
          loading: (_) => const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
