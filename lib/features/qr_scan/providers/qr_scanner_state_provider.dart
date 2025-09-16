import 'dart:async';

import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/data/provider/app_links/app_link.dart';
import 'package:coin_cz/features/qr_scan/qr_scan.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';

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
    if (arg.parseAction == QrScannerParseAction.returnRawValue) {
      if (input == null) {
        throw QrScannerInvalidQrParametersException();
      }

      if (arg.asset == null) {
        if (arg.onSuccessAction == QrOnSuccessNavAction.popBack) {
          state = AsyncValue.data(QrScanState.unknownQrCode(input));
          logger.debug('[QR][Process] '
              '- address: $input '
              '- parseAddress: ${arg.parseAction} '
              '- onSuccessAction: ${arg.onSuccessAction}');
        } else {
          throw QrScannerInvalidQrParametersException();
        }
      }

      final sendArgs =
          SendAssetArguments.fromAsset(arg.asset!).copyWith(input: input);
      state = arg.onSuccessAction == QrOnSuccessNavAction.popBack
          ? AsyncValue.data(QrScanState.pullSendAsset(sendArgs))
          : AsyncValue.data(QrScanState.pushSendAsset(sendArgs));
    } else {
      logger.debug('[QR][Process] attemp'
          '- address: $input '
          '- parseAddress: ${arg.parseAction} '
          '- onSuccessAction: ${arg.onSuccessAction}');
      state = await AsyncValue.guard(() async {
        final result = await ref
            .read(qrScannerProvider(arg))
            .parseQrAddressScan(input, asset: arg.asset);

        if (result == null) {
          throw QrScannerInvalidQrParametersException();
        }

        //TODO: Need to throw error if user is on privkey scan and they scan a pubkey
        return result.maybeWhen(
          lnurlWithdraw: (lnurlParseResult) {
            return QrScanState.lnurlWithdraw(lnurlParseResult.withdrawalParams);
          },
          send: (parsedAddress) async {
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
              externalPrivateKey: parsedAddress.extPrivateKey,
            );

            // ⚠️ if amount is invalid will show exception dialog with "Try again" button
            await ref.read(sendAssetAmountValidationProvider(sendArgs).future);

            // ✅ all good, return result
            return arg.onSuccessAction == QrOnSuccessNavAction.popBack
                ? QrScanState.pullSendAsset(sendArgs)
                : QrScanState.pushSendAsset(sendArgs);
          },
          samRock: (setupChains, otp, uploadUrl) {
            return QrScanState.samRock(SamRockAppLink(
              setupChains: setupChains,
              otp: otp,
              uploadUrl: uploadUrl,
            ));
          },
          orElse: () {
            throw QrScannerInvalidQrParametersException();
          },
        );
      });
    }
  }
}
