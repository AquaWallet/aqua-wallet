import 'dart:async';

import 'package:aqua/common/common.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:decimal/decimal.dart';

typedef ReceiveAddressParams = (Asset, Decimal?);

final receiveAssetAddressProvider = AutoDisposeAsyncNotifierProviderFamily<
    _Notifier, String, ReceiveAddressParams>(_Notifier.new);

class _Notifier
    extends AutoDisposeFamilyAsyncNotifier<String, ReceiveAddressParams> {
  var _addresses = <String, String>{};

  @override
  FutureOr<String> build((Asset, Decimal?) arg) async {
    final asset = arg.$1;
    final amount = arg.$2;

    // Lightning invoices come from boltz reverse swap state and change when new invoices
    // are generated. We skip caching to ensure we always get the current invoice.
    if (asset.isLightning) {
      final invoice = ref
              .watch(boltzReverseSwapProvider)
              .mapOrNull(qrCode: (res) => res.swap?.invoice) ??
          '';
      logger.debug('[Receive] Lightning invoice: $invoice');
      return invoice;
    }

    // For alt-USDT assets, the address comes from the swap order deposit address.
    if (asset.isAltUsdt) {
      final swapPair = ReceiveArguments.fromAsset(asset).swapPair;
      if (swapPair != null) {
        final swapState =
            ref.watch(swapOrderProvider(SwapArgs(pair: swapPair)));
        final depositAddress =
            swapState.valueOrNull?.order?.depositAddress ?? '';
        logger.debug('[Receive] AltUSDT deposit address: $depositAddress');
        return depositAddress;
      }
      return '';
    }

    final existingAddress = _addresses[asset.id];

    if (existingAddress?.isNotEmpty ?? false) {
      logger.debug('[Receive] Return ${asset.id}: ${_addresses[asset.id]}');
      return existingAddress!;
    }

    final address = await _generateAddress(asset, amount);
    //NOTE - The Sideshift implementation is too tightly coupled to have orders
    // cached reliably, so we are not caching the address for Sideshift.
    // Lightning addresses should not be cached as they come from boltz provider state
    if (!asset.isAltUsdt && !asset.isLightning) {
      _addresses[asset.id] = address;
    }
    logger.debug('[Receive] Generate ${asset.id}: $address');
    return address;
  }

  Future<void> forceRefresh() async {
    ref.invalidateSelf();
    _addresses = {};
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

      default:
        // Use the activeAltUSDtsProvider to check for alt-USDT assets
        final activeAltUSDts = ref.read(activeAltUSDtsProvider);
        if (activeAltUSDts.any((altUsdt) => altUsdt.id == asset.id)) {
          // For alt-USDT assets, get address from swap order
          final swapPair = ReceiveArguments.fromAsset(asset).swapPair;
          if (swapPair != null) {
            final swapArgs = SwapArgs(pair: swapPair);
            final swapOrderState = ref.read(swapOrderProvider(swapArgs));
            return swapOrderState.valueOrNull?.order?.depositAddress ?? '';
          }
          return '';
        }

        // default is all liquid assets
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
