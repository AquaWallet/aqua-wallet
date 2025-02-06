import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

final qrCodeStateProvider = AutoDisposeAsyncNotifierProviderFamily<
    QrScannerNotifier, QrScanState, QrScannerArguments>(QrScannerNotifier.new);

class QrScannerNotifier
    extends AutoDisposeFamilyAsyncNotifier<QrScanState, QrScannerArguments> {
  @override
  FutureOr<QrScanState> build(QrScannerArguments arg) async {
    final barcode = await ref.watch(qrScanProvider.future);
    if (barcode?.isNotEmpty ?? false) {
      processBarcode(barcode);
    }
    return const QrScanState.idle();
  }

  Future<void> processBarcode(String? input) async {
    logger.debug('[QR][Process] '
        '- address: $input '
        '- parseAddress: ${arg.parseAction} '
        '- onSuccessAction: ${arg.onSuccessAction}');

    if (arg.parseAction == QrScannerParseAction.doNotParse) {
      if (input == null) {
        throw QrScannerInvalidQrParametersException();
      }

      if (arg.asset == null) {
        if (arg.onSuccessAction == QrOnSuccessAction.pull) {
          state = AsyncValue.data(QrScanState.unknownQrCode(input));
        } else {
          throw QrScannerInvalidQrParametersException();
        }
      }

      final sendArgs =
          SendAssetArguments.fromAsset(arg.asset!).copyWith(input: input);
      state = arg.onSuccessAction == QrOnSuccessAction.pull
          ? AsyncValue.data(QrScanState.pullSendAsset(sendArgs))
          : AsyncValue.data(QrScanState.pushSendAsset(sendArgs));
    } else {
      state = await AsyncValue.guard(() async {
        final result = await ref
            .read(qrScannerProvider(arg))
            .parseQrAddressScan(input, asset: arg.asset);

        if (result == null) {
          throw QrScannerInvalidQrParametersException();
        }

        return result.maybeWhen(
          lnurlWithdraw: (lnurlParseResult) {
            return QrScanState.lnurlWithdraw(lnurlParseResult.withdrawalParams);
          },
          send: (parsedAddress) {
            if (arg.asset != null &&
                parsedAddress.asset != null &&
                arg.asset!.isCompatibleWith(parsedAddress.asset!) == false) {
              throw QrScannerIncompatibleAssetIdException();
            }

            final sendArgs =
                SendAssetArguments.fromAsset(parsedAddress.asset!).copyWith(
              input: parsedAddress.address,
              userEnteredAmount: parsedAddress.amount,
              lnurlParseResult: parsedAddress.lnurlParseResult,
            );

            return arg.onSuccessAction == QrOnSuccessAction.pull
                ? QrScanState.pullSendAsset(sendArgs)
                : QrScanState.pushSendAsset(sendArgs);
          },
          orElse: () {
            throw QrScannerInvalidQrParametersException();
          },
        );
      });
    }
  }
}
