import 'package:aqua/common/data_conversion/bip21_encoder.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/external/boltz/boltz_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'receive_asset_address_provider.g.dart';

// address
@riverpod
Future<String> receiveAssetAddress(ReceiveAssetAddressRef ref,
    {required Asset asset, double? amount}) async {
  switch (asset.id) {
    case 'btc':
      final gdkAddress = await ref.read(bitcoinProvider).getReceiveAddress();
      if (amount != null && amount > 0) {
        final address = gdkAddress?.address ?? '';
        final bip21Address = Bip21Encoder(
          address: address,
          amount: amount,
          network: NetworkType.bitcoin,
        ).encode();
        return bip21Address;
      } else {
        final address = gdkAddress?.address ?? '';
        final bip21Address =
            Bip21Encoder(address: address, network: NetworkType.bitcoin)
                .encode();
        return bip21Address;
      }

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
      if (amount != null && amount > 0) {
        final address = gdkAddress?.address ?? '';
        return Bip21Encoder(
                address: address,
                amount: amount,
                asset: asset,
                network: NetworkType.liquid)
            .encode();
      } else {
        final address = gdkAddress?.address ?? '';
        return Bip21Encoder(
                address: address, asset: asset, network: NetworkType.liquid)
            .encode();
      }
  }
}
