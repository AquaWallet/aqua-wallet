import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/boltz/boltz_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:decimal/decimal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

final receiveAssetAddressProvider = FutureProvider.autoDispose
    .family<String, (Asset, Decimal?)>((ref, params) async {
  final asset = params.$1;
  final amount = params.$2;

  switch (asset.id) {
    case 'btc':
      final gdkAddress = await ref.read(bitcoinProvider).getReceiveAddress();
      final address = gdkAddress?.address ?? '';
      if (amount != null && amount > Decimal.zero) {
        return Bip21Encoder(
          address: address,
          amount: amount,
          network: NetworkType.bitcoin,
        ).encode();
      }
      return Bip21Encoder(address: address, network: NetworkType.bitcoin)
          .encode();

    // lightning invoice comes from boltz reverse swap response
    case 'lightning':
      return ref.watch(boltzReverseSwapSuccessResponseProvider)?.invoice ?? '';

    // eth and tron addresses come from sideshift order
    case 'eth-usdt':
    case 'trx-usdt':
      final sideShiftOrder = ref.watch(pendingOrderProvider);
      return sideShiftOrder?.depositAddress ?? '';

    // default is all liquid assets
    default:
      final gdkAddress = await ref.read(liquidProvider).getReceiveAddress();
      final address = gdkAddress?.address ?? '';
      if (amount != null && amount > Decimal.zero) {
        return Bip21Encoder(
          address: address,
          amount: amount,
          asset: asset,
          network: NetworkType.liquid,
        ).encode();
      }
      return Bip21Encoder(address: address, network: NetworkType.liquid)
          .encode();
  }
});
