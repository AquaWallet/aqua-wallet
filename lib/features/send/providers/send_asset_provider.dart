import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';

/// ---------------------
/// Asset
final sendAssetProvider = StateProvider.autoDispose<Asset>((ref) {
  return Asset.unknown();
});

/// ---------------------
/// Insufficient Balance
final insufficientBalanceProvider = StateProvider.autoDispose<bool>((ref) {
  return false;
});

/// ---------------------
/// Note
final noteProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});
