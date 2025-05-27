import 'dart:async';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_pop_result.dart';
import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/text_scan/models/text_scan_arguments.dart';
import 'package:aqua/features/text_scan/models/text_scan_state.dart';
import 'package:aqua/features/text_scan/providers/text_scan_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.textScan);

final textScanStateProvider = AutoDisposeAsyncNotifierProviderFamily<
    TextScannerNotifier, TextScanState, TextScannerArguments>(
  TextScannerNotifier.new,
);

class TextScannerNotifier extends AutoDisposeFamilyAsyncNotifier<TextScanState,
    TextScannerArguments> {
  @override
  FutureOr<TextScanState> build(TextScannerArguments arg) async {
    final recognizedAddressesValue = ref.watch(textScanProvider);

    return recognizedAddressesValue.when(
      data: (addresses) async {
        if (addresses.isEmpty) {
          final isAfterScan = await _wasScanningAttempted();
          if (!isAfterScan) {
            return const TextScanState.idle();
          }
          return const TextScanState.unknownText('Error scanning the text');
        }

        final validList = await _filterValidAddresses(addresses, arg.asset);
        _logger.debug('validList: $validList, addresses: $addresses');

        if (validList.isEmpty) {
          return const TextScanState.unknownText('Error scanning the text');
        }

        if (arg.parseAction == TextScannerParseAction.returnRawValue) {
          _logger.debug('return raw value: $validList');
          return TextScanState.multipleRawValue(validList);
        }

        _logger.debug('attempt to parse: $validList');
        return TextScanState.addressSelection(validList);
      },
      loading: () => const TextScanState.loading(),
      error: (err, st) => const TextScanState.error(),
    );
  }

  Future<bool> _wasScanningAttempted() async {
    return ref.read(textScanProvider.notifier).wasScanAttempted();
  }

  Future<void> processSingleAddress(
      String singleAddress, TextScannerArguments arg) async {
    state = const AsyncValue.loading();
    final newState = await _parseAddress(singleAddress, arg);
    state = AsyncValue.data(newState);
  }

  Future<TextScanState> _parseAddress(
      String address, TextScannerArguments arg) async {
    try {
      final popResult =
          await ref.read(qrScannerProvider(arg)).parseQrAddressScan(
                address,
                asset: arg.asset,
              );

      if (popResult == null) {
        return const TextScanState.error("Invalid address");
      }

      return await _mapQrPopResultToTextScanState(popResult, arg);
    } catch (e) {
      _logger.error('Text parse error: $e');
      return const TextScanState.unknownText("Error during parse");
    }
  }

  Future<TextScanState> _mapQrPopResultToTextScanState(
    QrScannerPopResult result,
    TextScannerArguments arg,
  ) async {
    return result.when(
      send: (parsedAddress) async {
        final asset = parsedAddress.asset;
        if (asset == null) {
          return const TextScanState.unknownText('No asset found');
        }

        final sendArgs = SendAssetArguments.fromAsset(asset).copyWith(
          input: parsedAddress.address,
          userEnteredAmount: parsedAddress.amount,
          lnurlParseResult: parsedAddress.lnurlParseResult,
          externalPrivateKey: parsedAddress.extPrivateKey,
        );

        return arg.onSuccessAction == TextOnSuccessNavAction.popBack
            ? TextScanState.pullSendAsset(sendArgs)
            : TextScanState.pushSendAsset(sendArgs);
      },
      lnurlWithdraw: (lnurlResult) => TextScanState.lnurlWithdraw(
        lnurlResult.withdrawalParams,
      ),
      swap: (orderId, sendAsset, sendAmount, recvAsset, recvAmount,
              uploadUrl) =>
          const TextScanState.unknownText('Swap logic is not implemented yet'),
      samRock: (setupChains, otp, uploadUrl) => const TextScanState.unknownText(
          'SamRock logic is not implemented yet'),
      requiresRestart: () =>
          const TextScanState.unknownText('Requires restart'),
      empty: () => const TextScanState.unknownText('Empty result'),
    );
  }

  Future<List<String>> _filterValidAddresses(
    List<String> addresses,
    Asset? asset,
  ) async {
    final parser = ref.read(addressParserProvider);
    final assets = ref.read(assetsProvider).asData?.value ?? [];

    _logger.debug(
      '_filterValidAddresses - addresses: $addresses, asset: $asset, userAssets: $assets',
    );

    final validAddresses = <String>[];

    for (final addr in addresses) {
      try {
        final parsed = await parser.parseInput(asset: asset, input: addr);
        if (parsed == null) continue;

        final addressAsset = parsed.asset;
        _logger.debug('addressAsset: $addressAsset');

        if (addressAsset != null) {
          final foundInUserAssets = assets.any((a) => a.id == addressAsset.id);
          if (!foundInUserAssets) continue;
        }

        validAddresses.add(addr);
      } catch (e) {
        _logger.error('Error parsing address: $addr, error: $e');
      }
    }

    return validAddresses;
  }
}
