import 'package:aqua/logger.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/receive_qr_code/receive_qr_code_arguments.dart';
import 'package:aqua/data/provider/receive_qr_code/receive_qr_code_data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:rxdart/rxdart.dart';

final receiveQrCodeProvider = Provider.family
    .autoDispose<ReceiveQrCodeProvider, ReceiveQrCodeArguments>(
        (ref, arguments) => ReceiveQrCodeProvider(ref, arguments));

class ReceiveQrCodeProvider {
  ReceiveQrCodeProvider(this.ref, this.arguments) {
    ref.onDispose(() {
      _clipboardCopySubject.close();
    });
  }

  final AutoDisposeProviderRef ref;
  final ReceiveQrCodeArguments arguments;

  /// QR Data
  Future<ReceiveQrCodeData> get _qrCodeData async {
    // get address
    final address = await ref.watch(_addressProvider(arguments.asset).future);
    if (address == null) {
      throw ReceiveQrCodeProviderInvalidAddressException();
    }

    // get amount
    final amount = ref.watch(amountInputProvider);

    // return qr data
    // for onchain and liquid:
    // - if no amount, just form qr from address and nothing else
    // - if amount, form full url with `address`, `assetid`, `amount`
    final asset = arguments.asset;
    final network = asset.isBTC ? 'bitcoin://' : 'liquidnetwork://';
    if (amount != null && amount.isNotEmpty) {
      final qrImageData = '$network$address?assetid=${asset.id}&amount=$amount';
      logger.d('[RECEIVE] qrImageData: $qrImageData');
      return ReceiveQrCodeData(address: address, qrImageData: qrImageData);
    } else {
      final qrImageData = address;
      logger.d('[RECEIVE] qrImageData: $qrImageData');
      return ReceiveQrCodeData(address: address, qrImageData: qrImageData);
    }
  }

  Stream<AsyncValue<ReceiveQrCodeData>> get _qrCodeDataStream {
    return Stream.fromFuture(_qrCodeData)
        .map((data) => AsyncValue.data(data))
        .onErrorReturnWith(
            (error, stackTrace) => AsyncValue.error(error, stackTrace));
  }

  /// Clipboard + resulting snackbar opacity logic
  final PublishSubject<void> _clipboardCopySubject = PublishSubject();
  void copyAddressToClipboard() {
    _clipboardCopySubject.add(null);
  }

  late final Stream<AsyncValue<void>> _clipboardCopyProcessingStream =
      _clipboardCopySubject
          .switchMap((_) => _qrCodeDataStream
              .switchMap<String>((value) => value.maybeWhen(
                    data: (qrCodeData) => Stream.value(qrCodeData.address),
                    orElse: () => const Stream.empty(),
                  ))
              .first
              .then(
                  (address) => Clipboard.setData(ClipboardData(text: address)))
              .asStream()
              .map((value) => AsyncValue.data(value))
              .startWith(const AsyncValue.loading())
              .onErrorReturnWith(
                  (error, stackTrace) => AsyncValue.error(error, stackTrace)))
          .shareReplay(maxSize: 1);
  late final Stream<double> _addressCopiedSnackbarOpacityStream =
      _clipboardCopyProcessingStream
          .switchMap((value) => value.maybeWhen(
                data: (_) => Stream.value(1.0).concatWith([
                  Stream.value(0.0).delay(const Duration(milliseconds: 2000)),
                ]),
                orElse: () => Stream.value(0.0),
              ))
          .startWith(0.0);
  late final Stream<double> _addressCopyFailedSnackbarOpacityStream =
      _clipboardCopyProcessingStream
          .switchMap((value) => value.maybeWhen(
                error: (_, __) => Stream.value(1.0).concatWith([
                  Stream.value(0.0).delay(const Duration(milliseconds: 2000)),
                ]),
                orElse: () => Stream.value(0.0),
              ))
          .startWith(0.0);

  /// Navigation
  void navigateToAmount() {
    ref.read(navigateToAmountNotifier.notifier).state = Object();
  }

  void navigateToHistory() {
    ref.read(navigateToHistoryNotifier.notifier).state = Object();
  }

  void navigateToAddNote() {
    ref.read(navigateToAddNoteNotifier.notifier).state = Object();
  }
}

/// Main Provider for QR code
final receiveQrCodeAddressProvider = FutureProvider.family
    .autoDispose<ReceiveQrCodeData, ReceiveQrCodeArguments>((ref, arguments) {
  return ref.watch(receiveQrCodeProvider(arguments))._qrCodeData;
});

/// Amount Provider
final amountInputProvider = StateProvider<String?>((ref) => null);

/// Address Provider
final _addressProvider =
    FutureProvider.autoDispose.family<String?, Asset>((ref, asset) async {
  final addressDetails = asset.isBTC
      ? await ref.read(bitcoinProvider).getReceiveAddress()
      : await ref.read(liquidProvider).getReceiveAddress();

  return addressDetails?.address;
});

/// Snackbar Opacity Providers
final _receiveQrCodeAddressCopiedSnackbarOpacityStreamProvider = StreamProvider
    .family
    .autoDispose<double, ReceiveQrCodeArguments>((ref, arguments) async* {
  yield* ref
      .watch(receiveQrCodeProvider(arguments))
      ._addressCopiedSnackbarOpacityStream;
});

final receiveQrCodeAddressCopiedSnackbarOpacityProvider = Provider.family
    .autoDispose<double, ReceiveQrCodeArguments>((ref, arguments) {
  return ref
          .watch(_receiveQrCodeAddressCopiedSnackbarOpacityStreamProvider(
              arguments))
          .asData
          ?.value ??
      0.0;
});

final _receiveQrCodeAddressCopyFailedSnackbarOpacityStreamProvider =
    StreamProvider.family
        .autoDispose<double, ReceiveQrCodeArguments>((ref, arguments) async* {
  yield* ref
      .watch(receiveQrCodeProvider(arguments))
      ._addressCopyFailedSnackbarOpacityStream;
});

final receiveQrCodeAddressCopyFailedSnackbarOpacityProvider = Provider.family
    .autoDispose<double, ReceiveQrCodeArguments>((ref, arguments) {
  return ref
          .watch(_receiveQrCodeAddressCopyFailedSnackbarOpacityStreamProvider(
              arguments))
          .asData
          ?.value ??
      0.0;
});

/// NAVIGATION PROVIDERS

final navigateToAmountNotifier =
    StateProvider.autoDispose<Object?>((ref) => null);
final navigateToHistoryNotifier =
    StateProvider.autoDispose<Object?>((ref) => null);
final navigateToAddNoteNotifier =
    StateProvider.autoDispose<Object?>((ref) => null);

/// EXCEPTIONS

class ReceiveQrCodeProviderInvalidAddressException implements Exception {}

class ReceiveQrCodeProviderInvalidArgumentsException implements Exception {}
