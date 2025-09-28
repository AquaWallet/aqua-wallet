import 'package:freezed_annotation/freezed_annotation.dart';

part 'paginated_data.freezed.dart';

@freezed
class PaginatedData<T> with _$PaginatedData<T> {
  const factory PaginatedData({
    @Default([]) List<T> items,
    @Default(1) int nextPage,
    @Default(false) bool hasMore,
    @Default(false) bool isLoadingMore,
    @Default(null) Object? error,
  }) = _PaginatedData<T>;
}
