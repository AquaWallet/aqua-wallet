import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_list_args.freezed.dart';

@freezed
class AddressListArgs with _$AddressListArgs {
  const factory AddressListArgs({
    required NetworkType networkType,
    required Asset asset,
  }) = _AddressListArgs;
}
