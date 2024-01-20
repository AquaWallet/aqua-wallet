import 'package:aqua/features/shared/shared.dart';

/// ---------------------
/// Data Providers
///
/// - `_assetListProvider`: Transforms the arguments list into `AsyncValue<List<Asset>>`.
/// - `assetListDataProvider`: Fetches the asset list.
/// - `reloadNotifier`: Hook for refreshing the asset list.
///

final reloadNotifier = Provider.autoDispose<Object>((ref) => Object());
