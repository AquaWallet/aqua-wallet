import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/data/provider/app_links/app_links_provider.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_pop_result.dart';
import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:rxdart/rxdart.dart';

final qrScannerProvider = Provider.family
    .autoDispose<QrScannerProvider, Object?>(
        (ref, _) => QrScannerProvider(ref));

class QrScannerProvider {
  static const _qrParametersKeyAssetId = 'assetid';

  QrScannerProvider(this.ref) {
    ref.onDispose(() {
      _popWithRequiresRestartResultSubject.close();
      _permissionSubject.close();
    });
  }

  final AutoDisposeProviderRef ref;
  final PublishSubject<void> _popWithRequiresRestartResultSubject =
      PublishSubject();
  void popWithRequiresRestartResult() {
    _popWithRequiresRestartResultSubject.add(null);
  }

  late final Stream<AsyncValue<void>> _initializationStream = Stream.value(null)
      .switchMap((value) => Stream.value(null)
          .delay(const Duration(milliseconds: 2000))
          .map((_) => AsyncValue.data(_))
          .startWith(const AsyncValue.loading()))
      .shareReplay(maxSize: 1);

  final PublishSubject<bool> _permissionSubject = PublishSubject();
  void permissionSet(bool isPermissionSet) {
    _permissionSubject.add(isPermissionSet);
  }

  Stream<Object> _showPermissionAlertDialogStream() =>
      _permissionSubject.switchMap((isPermissionSet) =>
          isPermissionSet ? const Stream.empty() : Stream.value(Object()));

  /// Parse the result of the QR code scan based on asset type
  Future<QrScannerPopResult?> parseQrAddressScan(String? value,
      {String? network, Asset? asset}) async {
    if (value == null) {
      return null;
    }

    final uri = Uri.parse(value);

    // asset is passed - validate address for that asset
    if (asset != null) {
      final parsedInput = await ref
          .read(addressParserProvider)
          .parseInput(input: uri.toString(), asset: asset);

      if (parsedInput == null) {
        throw QrScannerInvalidQrParametersException();
      }

      final result = QrScannerPopResult.send(parsedAddress: parsedInput);
      logger.d('[QR] scanner result: $result');
      return result;
    }

    // asset is null - validate address for all valid assets
    else {
      // swap app link
      try {
        final appLink = ref.read(appLinkProvider).parseAppLinkUri(uri);

        if (appLink is SwapAppLink) {
          return QrScannerPopSwapResult(
            orderId: appLink.orderId,
            sendAsset: appLink.sendAsset,
            sendAmount: appLink.sendAmount,
            recvAsset: appLink.recvAsset,
            recvAmount: appLink.recvAmount,
            uploadUrl: appLink.uploadUrl,
          );
        }
      } catch (_) {}

      // all other assets
      final parsedInput = await ref
          .read(addressParserProvider)
          .parseInput(input: uri.toString());

      if (parsedInput == null) {
        throw QrScannerInvalidQrParametersException();
      }

      Asset? asset = parsedInput.asset;
      if (asset == null) {
        throw QrScannerInvalidQrParametersException();
      }

      // lnurl withdraw
      if (parsedInput.lnurlParseResult?.withdrawalParams != null) {
        return QrScannerPopLnurlWithdrawResult(
          lnurlParseResult: parsedInput.lnurlParseResult!,
        );
      }

      // if qr code assetId is not in user assets, throw exception
      final assets = ref.read(assetsProvider).asData?.value ?? [];
      if (asset.isLiquid) {
        if (uri.queryParameters[_qrParametersKeyAssetId] != null) {
          asset = assets.firstWhere(
            (asset) => asset.id == uri.queryParameters[_qrParametersKeyAssetId],
            orElse: () => throw QrScannerUnsupportedAssetIdException(),
          );
        }
      }

      final result = QrScannerPopResult.send(parsedAddress: parsedInput);

      logger.d('[QR] scanner result: $result');
      return result;
    }
  }
}

final _qrScannerInitializationStreamProvider = StreamProvider.family
    .autoDispose<AsyncValue<void>, Object?>((ref, arguments) async* {
  yield* ref.watch(qrScannerProvider(arguments))._initializationStream;
});

final qrScannerInitializationProvider =
    Provider.family.autoDispose<AsyncValue<void>, Object?>((ref, arguments) {
  return ref
          .watch(_qrScannerInitializationStreamProvider(arguments))
          .asData
          ?.value ??
      const AsyncValue.loading();
});

final _qrScannerShowPermissionAlertStreamProvider =
    StreamProvider.family.autoDispose<Object, Object?>((ref, arguments) async* {
  yield* ref
      .watch(qrScannerProvider(arguments))
      ._showPermissionAlertDialogStream();
});

final qrScannerShowPermissionAlertProvider =
    Provider.family.autoDispose<Object?, Object?>((ref, arguments) {
  return ref
      .watch(_qrScannerShowPermissionAlertStreamProvider(arguments))
      .asData
      ?.value;
});

class QrScannerInvalidQrParametersException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.tryAgain;
  }
}

class QrScannerUnsupportedAssetIdException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.scanQrCodeUnsupportedAssetAlertSubtitle;
  }
}

class QrScannerIncompatibleAssetIdException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.scanQrCodeIncompatibleAssetAlertSubtitle;
  }
}
