import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:ui_components/ui_components.dart' show AssetUiModel;

class SelectedAccountUiModel {
  final TypeOfAccount type;
  final AssetUiModel assetUiModel;

  const SelectedAccountUiModel(
      {required this.type, required this.assetUiModel});

  SelectedAccountUiModel copyWith({
    TypeOfAccount? type,
    AssetUiModel? assetUiModel,
  }) {
    return SelectedAccountUiModel(
      type: type ?? this.type,
      assetUiModel: assetUiModel ?? this.assetUiModel,
    );
  }

  bool get isSavingsAccount => type == TypeOfAccount.savings;
  bool get isSpendingAccount => type == TypeOfAccount.spending;

  bool isThisItemSelected(
          String assetId, SelectedAccountUiModel selectedAccount) =>
      selectedAccount.assetUiModel.assetId == assetId;
}

class HistoryOfAccountUiModel {
  final HistoryOfAccount type;
  final String name;

  const HistoryOfAccountUiModel({required this.type, required this.name});
}

class SwapOrderUiModel {
  final String title;
  final String subtitle;
  final String titleTrailing;
  final String subtitleTrailing;

  const SwapOrderUiModel({
    required this.title,
    required this.subtitle,
    required this.titleTrailing,
    required this.subtitleTrailing,
  });
}
