import 'package:aqua/features/shared/shared.dart';

abstract class PaginatedAsyncNotifier<T>
    extends AutoDisposeAsyncNotifier<PaginatedData<T>> {
  Future<PaginatedData<T>> fetch(int page);

  @override
  Future<PaginatedData<T>> build() async => fetch(1);

  Future<void> fetchNext() async {
    final value = state.value;
    if (value == null || !value.hasMore || value.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(value.copyWith(isLoadingMore: true, error: null));

    try {
      final newValue = await fetch(value.nextPage);
      state = AsyncValue.data(value.copyWith(
        items: [...value.items, ...newValue.items],
        nextPage: newValue.nextPage,
        hasMore: newValue.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncValue.data(value.copyWith(isLoadingMore: false, error: e));
    }
  }
}

abstract class PaginatedAsyncNotifierFamily<T, A>
    extends AutoDisposeFamilyAsyncNotifier<PaginatedData<T>, A> {
  Future<PaginatedData<T>> fetch(int page, A id);

  @override
  Future<PaginatedData<T>> build(A arg) async => fetch(1, arg);

  Future<void> fetchNext() async {
    final value = state.value;
    if (value == null || !value.hasMore || value.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(value.copyWith(isLoadingMore: true, error: null));

    try {
      final newValue = await fetch(value.nextPage, arg);
      state = AsyncValue.data(value.copyWith(
        items: [...value.items, ...newValue.items],
        nextPage: newValue.nextPage,
        hasMore: newValue.hasMore,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncValue.data(value.copyWith(isLoadingMore: false, error: e));
    }
  }
}
