import 'package:aqua/features/send/widgets/insufficient_balance_sheet.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';

/// ---------------------
/// Asset
final sendAssetProvider = StateProvider.autoDispose<Asset>((ref) {
  return Asset.unknown();
});

/// ---------------------
/// Insufficient Balance
final insufficientBalanceProvider =
    StateProvider.autoDispose<InsufficientFundsType?>((ref) {
  return null;
});

/// ---------------------
/// Note
final noteProvider = StateProvider.autoDispose<String?>((ref) {
  return null;
});
