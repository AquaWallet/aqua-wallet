import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

final receiveAssetAddressProvider = FutureProvider.autoDispose
    .family<String, (Asset, Decimal?)>((ref, params) async {
  final asset = params.$1;
  final amount = params.$2;

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
      final sideShiftOrder = ref.watch(sideshiftPendingOrderProvider);
      return sideShiftOrder?.depositAddress ?? '';

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
});
