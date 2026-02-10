import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';

final _logger = CustomLogger(FeatureFlag.swapOrderStorage);

enum SwapOrderFilterType {
  active,
  history;

  List<SwapOrderStatus> get statuses {
    switch (this) {
      case SwapOrderFilterType.active:
        return [
          SwapOrderStatus.waiting,
          SwapOrderStatus.processing,
          SwapOrderStatus.exchanging,
          SwapOrderStatus.sending,
          SwapOrderStatus.refunding,
        ];
      case SwapOrderFilterType.history:
        return [
          SwapOrderStatus.completed,
          SwapOrderStatus.failed,
          SwapOrderStatus.refunded,
          SwapOrderStatus.expired,
          SwapOrderStatus.unknown,
        ];
    }
  }
}

final swapOrdersFilterProvider = AutoDisposeAsyncNotifierProvider.family<
    SwapOrdersFilterNotifier,
    PaginatedData<SwapOrderDbModel>,
    SwapOrderFilterType>(SwapOrdersFilterNotifier.new);

class SwapOrdersFilterNotifier extends PaginatedAsyncNotifierFamily<
    SwapOrderDbModel, SwapOrderFilterType> {
  static const _kPerPage = 10;
  String _searchQuery = '';

  @override
  Future<PaginatedData<SwapOrderDbModel>> fetch(
    int page,
    // ignore: avoid_renaming_method_parameters
    SwapOrderFilterType type,
  ) async {
    _logger.debug('[SwapOrders] Fetching orders: Page $page, Type: $type');

    final offset = (page - 1) * _kPerPage;

    // Fetch paginated data from storage
    final items =
        await ref.read(swapStorageProvider.notifier).getOrdersPaginated(
              statuses: type.statuses,
              offset: offset,
              limit: _kPerPage + 1, // Fetch one extra to check if there's more
              searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
            );

    final hasMore = items.length > _kPerPage;
    final pageItems = hasMore ? items.take(_kPerPage).toList() : items;

    return PaginatedData(
      items: pageItems,
      nextPage: page + 1,
      hasMore: hasMore,
    );
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    ref.invalidateSelf();
  }

  void clearSearch() {
    _searchQuery = '';
    ref.invalidateSelf();
  }
}
