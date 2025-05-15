import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:decimal/decimal.dart';

part 'network_amount.freezed.dart';

/// This is a simple struct that represents a crypto amount and the asset it belongs to.
/// The amount should be denomiated in the Asset's unit as it is used on the Asset's network.
///
/// ie.
/// - BTC and LBTC should be denominated in sats
/// - USDt on Liquid is denominated like sats, where $1 USDt is 100 000 000 on the liquid network
/// - For altcoins, we need to use their respective networks denominations as well
@freezed
class NetworkAmount with _$NetworkAmount {
  const factory NetworkAmount({
    required Decimal amount,
    required Asset asset,
  }) = _NetworkAmount;

  // Static factory for a zero amount
  static NetworkAmount zero(Asset asset) => NetworkAmount(
        amount: Decimal.zero,
        asset: asset,
      );
}
