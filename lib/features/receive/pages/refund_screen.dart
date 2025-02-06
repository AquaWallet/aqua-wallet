import 'dart:convert';

import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/config/theme/theme.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class RefundArguments {
  final String address;
  final BoltzSwapDbModel swapData;
  final BoltzSwapStatus swapStatus;

  const RefundArguments(this.address, this.swapData, this.swapStatus);
}

enum RefundUIState {
  loading,
  alreadyRefunded,
  timelockNotExpired,
  refundReady,
  refundError
}

Future<void> downloadJson(
    String jsonString, String fileName, String dialogTitle) async {
  try {
    final savedFilePath = await FlutterFileSaver().writeFileAsString(
      fileName: fileName,
      data: jsonString,
    );

    logger.debug('File saved at $savedFilePath');
    final result =
        await Share.shareXFiles([XFile(savedFilePath)], text: dialogTitle);

    if (result.status == ShareResultStatus.success) {
      logger.debug('Shared filed success');
    }
  } catch (e) {
    logger.debug('An error occurred while saving the file: $e');
  }
}

class RefundScreen extends HookConsumerWidget {
  static const routeName = '/refundScreen';

  const RefundScreen({super.key, required this.arguments});
  final RefundArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = useState(RefundUIState.timelockNotExpired);
    final processRefundLoadingState = useState<bool>(false);
    final refundTxState = useState<String?>(null);
    final currentBlockHeight =
        ref.watch(fetchBlockHeightProvider(NetworkType.liquid)).asData?.value;
    final unlockDate = currentBlockHeight != null
        ? DateTime.now().add(Duration(
            minutes: (arguments.swapData.locktime - currentBlockHeight)))
        : null;
    final refundDataFuture = ref
        .read(boltzSubmarineSwapProvider.notifier)
        .getRefundData(arguments.swapData);

    useEffect(() {
      Future<void> determineUIState() async {
        if (arguments.swapData.refundTxId != null &&
            arguments.swapData.refundTxId!.isNotEmpty) {
          uiState.value = RefundUIState.alreadyRefunded;
        } else {
          if (currentBlockHeight == null) {
            uiState.value = RefundUIState.loading;
            return;
          }

          final timeoutBlockHeight = arguments.swapData.locktime;
          logger.debug(
              "[Boltz] Refund - currentBlockHeight: $currentBlockHeight - timeoutBlockHeight: $timeoutBlockHeight - blocks left: ${timeoutBlockHeight - currentBlockHeight}");

          if (currentBlockHeight < timeoutBlockHeight) {
            uiState.value = RefundUIState.timelockNotExpired;
          } else {
            uiState.value = RefundUIState.refundReady;
          }
        }
      }

      determineUIState();

      return null;
    }, [arguments, currentBlockHeight]);

    Widget content;
    switch (uiState.value) {
      case RefundUIState.alreadyRefunded:
        content = Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 60.0),
              Text(context.loc.boltzRefundAlreadyProcessedTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.left),
              const SizedBox(height: 40.0),
              LabelCopyableTextView(
                label: context.loc.boltzRefundTx,
                value: '${arguments.swapData.refundTxId}',
              ),
            ],
          ),
        );
        break;
      case RefundUIState.timelockNotExpired:
        content = FutureBuilder<BoltzRefundData?>(
          future: refundDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final refundData = snapshot.data;
            if (refundData == null) {
              return const Text('No refund data available');
            }

            return Container(
              width: double.maxFinite,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 60.0),
                  Text('${context.loc.boltzRefundWaitingTimeoutTitle}:',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  if (unlockDate != null) ...[
                    const SizedBox(height: 40.0),
                    Text(
                      unlockDate.formatFullDateTime,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 40.0),
                  Text(
                      '${context.loc.boltzRefundCurrentBlockHeightSubtitle}: $currentBlockHeight',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 15.0),
                  Text(
                      '${context.loc.boltzRefundTimeoutSubtitle}: ${arguments.swapData.locktime}',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 40.0),

                  //ANCHOR - Copy Refund Data
                  Text('${context.loc.boltzManualRefundTitle}:',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 15.0),

                  TextButton(
                    style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.secondary,
                        textStyle: Theme.of(context).textTheme.titleLarge),
                    onPressed: () async {
                      final jsonString = jsonEncode(refundData.toJson());
                      context.copyToClipboard(jsonString);
                    },
                    child: Text(context.loc.boltzCopyRefundData),
                  ),
                ],
              ),
            );
          },
        );
        break;
      case RefundUIState.refundReady:
        content = Container(
          width: double.maxFinite,
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 60.0),
              Text(context.loc.boltzRefundReadyToProcessTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center),

              // Refund Button
              const SizedBox(height: 40.0),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.errorContainer,
                    width: 2.0,
                  ),
                  textStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 18.0,
                      ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                ),
                onPressed: () async {
                  processRefundLoadingState.value = true;

                  try {
                    final swap = await ref
                        .read(boltzStorageProvider.notifier)
                        .getLbtcLnV2SwapById(arguments.swapData.boltzId);
                    if (swap == null) {
                      uiState.value = RefundUIState.refundError;
                      return;
                    }

                    final refundTx = await ref
                        .read(boltzSwapSettlementServiceProvider)
                        .refund(swap);

                    if (refundTx != null) {
                      refundTxState.value = refundTx;
                    } else {
                      uiState.value = RefundUIState.refundError;
                    }
                  } catch (e) {
                    uiState.value = RefundUIState.refundError;
                    logger.debug("[Boltz] Error processing refund: $e");
                  }
                },
                child: Text(context.loc.boltzProcessRefund),
              ),
              const SizedBox(height: 40.0),

              // Refund Success - Show tx
              if (refundTxState.value != null) ...[
                LabelCopyableTextView(
                  label: context.loc.boltzRefundTx,
                  value: '${refundTxState.value}}',
                ),
              ],

              if (processRefundLoadingState.value) ...[
                const SizedBox(height: 40.0),
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ],
            ],
          ),
        );
        break;
      case RefundUIState.refundError:
        content = FutureBuilder<BoltzRefundData?>(
          future: refundDataFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            final refundData = snapshot.data;
            if (refundData == null) {
              return const Text('No refund data available');
            }

            return Container(
              width: double.maxFinite,
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const SizedBox(height: 40.0),
                  Text(context.loc.boltzProcessRefundManualProcess,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center),

                  // Step 1: Download Refund Json
                  const SizedBox(height: 50.0),
                  Text(context.loc.boltzSaveRefundFile,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 22.0),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colors.onBackground,
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.0,
                      ),
                      textStyle:
                          Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontSize: 12.0,
                              ),
                    ),
                    onPressed: () {
                      final jsonString = jsonEncode(refundData.toJson());
                      downloadJson(
                          jsonString,
                          'boltz_refund_data_${arguments.swapData.boltzId}.json',
                          context.loc.boltzSaveFilePrompt);
                    },
                    child: Text(context.loc.save),
                  ),
                  const SizedBox(height: 50.0),

                  // Step 2: Copy Refund Address
                  Text(context.loc.boltzCopyRefundAddress,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20.0),
                  FutureBuilder<GdkReceiveAddressDetails?>(
                    future: ref.read(liquidProvider).getReceiveAddress(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return LabelCopyableTextView(
                            label: context.loc.boltzRefundAddress,
                            value: snapshot.data!.address ?? '',
                          );
                        } else if (snapshot.hasError) {
                          return Text(
                              '${context.loc.boltzReceiveAddressError}: ${snapshot.error}');
                        } else {
                          return Text(context.loc.boltzReceiveAddressError);
                        }
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                  const SizedBox(height: 50.0),

                  // Step 3: Boltz Refund Page
                  Text(context.loc.boltzUploadJsonRefund,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 20.0),
                  InkWell(
                    onTap: () => launchUrl(Uri.parse(boltzMainnetRefundUrl)),
                    child: Text(
                      boltzMainnetRefundUrl,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                    ),
                  ),
                  const SizedBox(height: 50.0),
                ],
              ),
            );
          },
        );
        break;
      case RefundUIState.loading:
        content = Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ],
          ),
        );
        break;
      default:
        content = Text(context.loc.boltzRefundUnknownStatus,
            style: Theme.of(context).textTheme.titleLarge);
    }

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AquaAppBar(
        title: context.loc.refund,
        showBackButton: true,
        showActionButton: false,
        backgroundColor:
            Theme.of(context).colors.transactionAppBarBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        iconOutlineColor: Theme.of(context).colors.appBarIconOutlineColorAlt,
        iconBackgroundColor:
            Theme.of(context).colors.appBarIconBackgroundColorAlt,
        iconForegroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
      body: Center(child: content),
    );
  }
}
