import 'package:aqua/data/models/gdk_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'address_lists.freezed.dart';

@freezed
class AddressLists with _$AddressLists {
  const factory AddressLists({
    required List<GdkPreviousAddress> usedAddresses,
    required List<GdkPreviousAddress> unusedAddresses,
    int? lastPointer,
    @Default(false) bool hasMore,
    @Default('') String searchQuery,
  }) = _AddressLists;
}
