import 'package:coin_cz/features/wallet/models/subaccount.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'subaccounts.freezed.dart';
part 'subaccounts.g.dart';

@freezed
class Subaccounts with _$Subaccounts {
  const factory Subaccounts({
    @Default([]) List<Subaccount> subaccounts,
  }) = _Subaccounts;

  factory Subaccounts.fromJson(Map<String, dynamic> json) =>
      _$SubaccountsFromJson(json);
}
