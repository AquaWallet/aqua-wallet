import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
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
    logger.d("[Send][Build] -- build review screen --");

    // asset
    final asset = ref.watch(sendAssetProvider);

    // amount display
    final amountDisplay = ref.watch(amountMinusFeesToDisplayProvider) ??
        arguments?.userEnteredAmount.toString() ??
        '-';

    // fees
    final fee = ref.watch(estimatedFeeProvider);
    final feeAsset = ref.watch(userSelectedFeeAssetProvider);
    final insufficientBalance = ref.watch(insufficientBalanceProvider);

    // transaction
    final transaction = ref.watch(sendAssetTransactionProvider).asData?.value;

    // ui
    final feeToDisplay = ref.watch(totalFeeToDisplayProvider(asset));
    final note = ref.watch(noteProvider);

    // error
    final error = ref.watch(sendAmountErrorProvider);

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

    // push to complete screen
    void pushToCompleteScreen(String txId, int timestamp, NetworkType network) {
      if (asset.isLightning) {
        final amountSatoshi =
            ref.read(formatterProvider).parseAssetAmountDirect(
                  amount: ref.read(userEnteredAmountProvider).toString(),
                  precision: asset.precision,
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
        Navigator.of(context).pushNamed(
          SendAssetTransactionCompleteScreen.routeName,
          arguments:
              SendAssetCompletionArguments(timestamp: timestamp, txId: txId),
        );
      }
    }

    // on confirm swipe
    final onTransactionConfirm = useCallback(() {
      ref
          .read(sendAssetTransactionProvider.notifier)
          .signAndBroadcastTransaction(onSuccess: pushToCompleteScreen);
    }, [fee, note]);

    // create initial tx
    final createTransaction = useCallback(() {
      if (asset == Asset.unknown()) return;
      logger.d("[Send] send review - create transaction");
      if (asset.isLightning) {
        ref.read(boltzProvider).createOnchainTxForCurrentNormalSwap();
      } else if (asset.isSideshift) {
        ref.read(sideshiftOrderProvider).createOnchainTxForSwap();
      } else if (feeAsset == FeeAsset.tetherUsdt) {
        ref.read(sendAssetTransactionProvider.notifier).createTaxiPsbt();
      } else {
        ref.read(sendAssetTransactionProvider.notifier).createGdkTransaction();
      }
    }, []);

    // listen to setup
    ref.listen(sendAssetSetupProvider, (_, setup) {
      if (setup.asData?.value == true) {
        createTransaction();
      }
    });

    // listen to user changes
    ref.listen(userSelectedFeeAssetProvider, (_, __) {
      _debouncer.run(() {
        createTransaction();
      });
    });

    ref.listen(userSelectedFeeRatePerVByteProvider, (_, __) {
      _debouncer.run(() {
        createTransaction();
      });
    });

    ref.listen(customFeeInputProvider, (_, __) {
      _debouncer.run(() {
        createTransaction();
      });
    });

    return WillPopScope(
      onWillPop: () async {
        logger.d('[Navigation] onWillPop in SendAssetScreen called');
        ref.read(sideshiftOrderProvider).stopAllStreams();
        return true;
      },
      child: Scaffold(
        appBar: AquaAppBar(
          showActionButton: false,
          title: context.loc.sendAssetScreenTitle,
          backgroundColor: Theme.of(context).colors.altScreenBackground,
          iconBackgroundColor: Theme.of(context).colors.altScreenSurface,
        ),
        backgroundColor: Theme.of(context).colors.altScreenBackground,
        body: ref.watch(sendAssetSetupProvider).map(
              data: (_) {
                return Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 28.w, vertical: 32.h),
                  child: Column(
                    children: [
                      //ANCHOR - Send Review Card
                      //Sideshift
                      if (asset.isSideshift) ...[
                        Text(
                          context.loc.sendAssetReviewScreenGenericLabel(
                              asset.network, asset.symbol),
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
                        if (transaction != null)
                          TransactionPrioritySelector(transaction: transaction),
                        SizedBox(
                          height: 10.h,
                        ),
                      }
                      // Sideshift (usdt-eth & trx) or Boltz (lighting)
                      else if (asset.isSideshift || asset.isLightning) ...{
                        if (transaction != null && feeToDisplay != null)
                          const GenericAssetTransactionFeeCard(),
                      }
                      // All Liquid Assets
                      else ...{
                        UsdtTransactionFeeSelector(
                            asset: asset, transaction: transaction),
                      },
                      SizedBox(height: 10.h),
                      //ANCHOR - Add Note
                      if (addNoteEnabled) ...{
                        const AddNoteButton(),
                        const Spacer(),
                      },
                      //ANCHOR - Fixed Error
                      CustomError(
                          errorMessage: error?.toLocalizedString(context)),
                      const Spacer(),
                      //ANCHOR - Confirmation Slider or Error
                      Consumer(
                        builder: (context, ref, child) {
                          return ref.watch(sendAssetTransactionProvider).when(
                                data: (_) {
                                  return SendAssetConfirmSlider(
                                    text: insufficientBalance != null
                                        ? context.loc
                                            .sendAssetAmountScreenNotEnoughFundsError
                                        : context.loc
                                            .sendAssetReviewScreenConfirmSlider,
                                    enabled: insufficientBalance == null &&
                                        transaction != null,
                                    onConfirm: onTransactionConfirm,
                                  );
                                },
                                loading: () =>
                                    const CircularProgressIndicator(),
                                error: (error, _) {
                                  final String errorMessage;
                                  if (error is ExceptionLocalized) {
                                    errorMessage =
                                        error.toLocalizedString(context);
                                  } else {
                                    errorMessage = error.toString();
                                  }

                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                );
              },
              error: (asyncError) {
                final error = asyncError.error;
                final String errorMessage;
                if (error is ExceptionLocalized) {
                  errorMessage = error.toLocalizedString(context);
                } else {
                  errorMessage = error.toString();
                }

                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: CustomError(errorMessage: errorMessage),
                    ),
                    const SizedBox(height: 80.0),
                  ],
                );
              },
              loading: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
            ),
      ),
    );
  }
}
