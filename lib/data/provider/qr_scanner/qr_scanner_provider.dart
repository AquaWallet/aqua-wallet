import 'package:aqua/data/models/exception_localized.dart';
import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/data/provider/app_links/app_links_provider.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_pop_result.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:rxdart/rxdart.dart';

final qrScannerProvider = Provider.family
    .autoDispose<QrScannerProvider, Object?>(
        (ref, _) => QrScannerProvider(ref));

class QrScannerProvider {
  static const _qrParametersKeyAssetId = 'assetid';
  static const _qrParametersKeyAmount = 'amount';
  static const _qrParametersKeyLabel = 'label';
  static const _qrParametersKeyMessage = 'message';

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
  Future<QrScannerPopResult?> validateQrAddressScan(String? value,
      {String? network, Asset? asset}) async {
    if (value == null) {
      return null;
    }

    final uri = Uri.parse(value);
    final address = uri.path;

    // asset is passed - validate address for that asset
    if (asset != null) {
      final isValid = await ref
          .read(addressParserProvider)
          .isValidAddressForAsset(asset: asset, address: address);
      if (isValid) {
        return QrScannerPopSuccessResult(
          address: address,
          asset: asset,
        );
      } else {
        throw QrScannerInvalidQrParametersException();
      }
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

      final validAsset = await ref
          .read(addressParserProvider)
          .isValidAddress(address: address);
      if (validAsset == null) {
        throw QrScannerInvalidQrParametersException();
      }

      // usdt-eth and usdt-trx
      if (validAsset.isEth || validAsset.isTrx) {
        return QrScannerPopSuccessResult(
          address: address,
          asset: validAsset,
        );
      }

      // lightning
      if (validAsset.isLightning) {
        try {
          final lnRequest = Bolt11PaymentRequest(uri.path);

          return QrScannerPopSuccessResult(
            address: uri.path,
            asset: Asset.lightning(),
            amount: lnRequest.amount.toString(),
          );
        } catch (_) {}
      }

      // bitcoin and liquid
      final assets = ref.read(assetsProvider).asData?.value ?? [];

      late Asset asset;

      final isLiquid = await ref
          .read(addressParserProvider)
          .isValidAddressForAsset(asset: Asset.liquid(), address: address);
      final isBitcoin = await ref
          .read(addressParserProvider)
          .isValidAddressForAsset(asset: Asset.btc(), address: address);

      if (network == 'Liquid' && !isLiquid) {
        throw QrScannerInvalidQrParametersException();
      }

      if (network == 'Bitcoin' && !isBitcoin) {
        throw QrScannerInvalidQrParametersException();
      }

      // parse bitcoin or liquid for asset
      if (isLiquid) {
        if (uri.queryParameters[_qrParametersKeyAssetId] != null) {
          // if qr code assetId is not in user assets, throw exception
          asset = assets.firstWhere(
            (asset) => asset.id == uri.queryParameters[_qrParametersKeyAssetId],
            orElse: () => throw QrScannerUnsupportedAssetIdException(),
          );
        } else {
          asset = assets.firstWhere((asset) => asset.isLBTC);
        }
      } else if (isBitcoin) {
        asset = assets.firstWhere((asset) => asset.isBTC);
      }

      // parse for amount, label, message
      try {
        final amount = uri.queryParameters.containsKey(_qrParametersKeyAmount)
            ? uri.queryParameters[_qrParametersKeyAmount]
            : null;

        final label = uri.queryParameters.containsKey(_qrParametersKeyLabel)
            ? uri.queryParameters[_qrParametersKeyLabel]
            : null;

        final message = uri.queryParameters.containsKey(_qrParametersKeyMessage)
            ? uri.queryParameters[_qrParametersKeyMessage]
            : null;

        final result = QrScannerPopSuccessResult(
          address: address,
          asset: asset,
          amount: amount,
          label: label,
          message: message,
        );

        return result;
      } catch (_) {
        throw QrScannerInvalidQrParametersException();
      }
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
    return AppLocalizations.of(context)!.scanQrCodeValidationAlertRetryButton;
  }
}

class QrScannerUnsupportedAssetIdException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return AppLocalizations.of(context)!
        .scanQrCodeUnsupportedAssetAlertSubtitle;
  }
}
