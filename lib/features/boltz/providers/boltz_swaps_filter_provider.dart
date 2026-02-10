import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';

final _logger = CustomLogger(FeatureFlag.boltzStorage);

final boltzSwapsFilterProvider = AutoDisposeAsyncNotifierProvider.family<
    BoltzSwapsFilterNotifier,
    PaginatedData<BoltzSwapDbModel>,
    SwapType>(BoltzSwapsFilterNotifier.new);

class BoltzSwapsFilterNotifier
    extends PaginatedAsyncNotifierFamily<BoltzSwapDbModel, SwapType> {
  static const _kPerPage = 10;
  String _searchQuery = '';

  @override
  // ignore: avoid_renaming_method_parameters
  Future<PaginatedData<BoltzSwapDbModel>> fetch(int page, SwapType type) async {
    _logger.debug('[BoltzSwaps] Fetching swaps: Page $page, Type: $type');

    final offset = (page - 1) * _kPerPage;
    final items =
        await ref.read(boltzStorageProvider.notifier).getSwapsPaginated(
              type: type,
              offset: offset,
              searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
              limit: _kPerPage + 1,
            );
    final hasMore = items.length > _kPerPage;
    final pageItems = hasMore ? items.take(_kPerPage).toList() : items;

    _logger.debug('[BoltzSwaps] Count: ${pageItems.length}, HasMore: $hasMore');

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
