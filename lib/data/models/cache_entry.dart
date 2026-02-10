import 'package:freezed_annotation/freezed_annotation.dart';

part 'cache_entry.freezed.dart';
part 'cache_entry.g.dart';

@freezed
class CacheEntry with _$CacheEntry {
  const CacheEntry._();

  const factory CacheEntry({
    required String value,
    required DateTime timestamp,
  }) = _CacheEntry;

  factory CacheEntry.fromJson(Map<String, dynamic> json) =>
      _$CacheEntryFromJson(json);
}
