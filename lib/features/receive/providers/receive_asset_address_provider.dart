import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

typedef ReceiveAddressParams = (Asset, Decimal?);

final receiveAssetAddressProvider = AutoDisposeAsyncNotifierProviderFamily<
    _Notifier, String, ReceiveAddressParams>(_Notifier.new);

class _Notifier
    extends AutoDisposeFamilyAsyncNotifier<String, ReceiveAddressParams> {
  final _addresses = <String, String>{};

  @override
  FutureOr<String> build((Asset, Decimal?) arg) async {
    //NOTE: Provider is marked AutoDispose only because boltz provider needs it.
    // The keepAlive prevents the provider from being disposed. The provider is
    // invalidated manually when the user leaves the [TransactionMenuScreen].
    ref.keepAlive();

    final asset = arg.$1;
    final amount = arg.$2;

    final existingAddress = _addresses[asset.id];

    if (existingAddress?.isNotEmpty ?? false) {
      logger.d('[Receive] Return ${asset.id}: ${_addresses[asset.id]}');
      return existingAddress!;
    }

    final address = await _generateAddress(asset, amount);
    //NOTE - The Sideshift implementation is too tightly coupled to have orders
    // cached reliably, so we are not caching the address for Sideshift.
    if (!asset.isAnyAltUsdt) {
      _addresses[asset.id] = address;
    }
    logger.d('[Receive] Generate ${asset.id}: $address');
    return address;
  }

  Future<String> _generateAddress(Asset asset, Decimal? amount) async {
    switch (asset.id) {
      case 'btc':
        final gdkAddress = await ref.read(bitcoinProvider).getReceiveAddress();
        final address = gdkAddress?.address ?? '';
        if (amount != null && amount > Decimal.zero) {
          // for btc, pass decimal format
          final amountDecimalFormat =
              (amount.toBigInt().toInt() / satsPerBtc).toStringAsFixed(8);
          return Bip21Encoder(
            address: address,
            amount: Decimal.parse(amountDecimalFormat),
            network: NetworkType.bitcoin,
          ).encode();
        }
        return Bip21Encoder(address: address, network: NetworkType.bitcoin)
            .encode();

      // lightning invoice comes from boltz reverse swap response
      case 'lightning':
        return ref
                .watch(boltzReverseSwapProvider)
                .mapOrNull(qrCode: (res) => res.swap?.invoice) ??
            '';

      // eth and tron addresses come from sideshift order
      case 'eth-usdt':
      case 'trx-usdt':
        throw UnimplementedError('Use sideshift address from the order');

      // default is all liquid assets
      default:
        final gdkAddress = await ref.read(liquidProvider).getReceiveAddress();
        final address = gdkAddress?.address ?? '';
        if (amount != null && amount > Decimal.zero) {
          final amountDecimalFormat = asset.isLBTC
              // for lbtc, pass decimal format
              ? (amount.toBigInt().toInt() / satsPerBtc).toStringAsFixed(8)
              : null;

          return Bip21Encoder(
            address: address,
            amount: amountDecimalFormat != null
                ? Decimal.parse(amountDecimalFormat)
                : amount,
            asset: asset,
            network: NetworkType.liquid,
          ).encode();
        }
        return Bip21Encoder(address: address, network: NetworkType.liquid)
            .encode();
    }
  }
}
