import 'package:aqua/features/settings/settings.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nanoid/nanoid.dart';

part 'receive_addresses_history_arguments.freezed.dart';

@freezed
class ReceiveAddressesHistoryArguments with _$ReceiveAddressesHistoryArguments {
  const factory ReceiveAddressesHistoryArguments._({
    required String id,
    required Asset asset,
  }) = AddressesHistoryArguments;

  factory ReceiveAddressesHistoryArguments.fromAsset(Asset asset) {
    return ReceiveAddressesHistoryArguments._(id: nanoid(), asset: asset);
  }
}
