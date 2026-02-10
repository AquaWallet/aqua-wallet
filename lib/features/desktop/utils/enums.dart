import 'package:ui_components/ui_components.dart';

enum AddressTabValues { used, unused }

enum SwapOrderTabValues { send, receive }

enum TypeOfAccount { savings, spending }

enum HistoryOfAccount { transactions, address, swapOrders }

extension HistoryOfAccountX on HistoryOfAccount {
  bool get isTransactions => this == HistoryOfAccount.transactions;
  bool get isAddress => this == HistoryOfAccount.address;
  bool get isSwapOrders => this == HistoryOfAccount.swapOrders;
}

extension AquaTransactionTypeX on AquaTransactionType {
  bool get isSend => this == AquaTransactionType.send;
  bool get isReceive => this == AquaTransactionType.receive;
  bool get isSwap => this == AquaTransactionType.swap;
}

enum WalletOnboardingDialog {
  createWallet,
  restoreWallet,
}

enum SelectedSettingsPageItem {
  walletDetails,
  manageAssets,
  advanced,
  region,
  language,
  unitCurrency,
  theme,
  explorer,
  security,
  bitcoinChip,
  none,
}

extension SelectedSettingsPageItemX on SelectedSettingsPageItem {
  bool get isWalletDetails => this == SelectedSettingsPageItem.walletDetails;
  bool get isManageAssets => this == SelectedSettingsPageItem.manageAssets;
  bool get isAdvanced => this == SelectedSettingsPageItem.advanced;
  bool get isRegion => this == SelectedSettingsPageItem.region;
  bool get isLanguage => this == SelectedSettingsPageItem.language;
  bool get isUnitCurrency => this == SelectedSettingsPageItem.unitCurrency;
  bool get isTheme => this == SelectedSettingsPageItem.theme;
  bool get isExplorer => this == SelectedSettingsPageItem.explorer;
  bool get isSecurity => this == SelectedSettingsPageItem.security;
  bool get isBitcoinChip => this == SelectedSettingsPageItem.bitcoinChip;
  bool get isNone => this == SelectedSettingsPageItem.none;
}

enum ExportWatchOnlyTabBarValues { bitcoin, liquid }

extension ExportWatchOnlyTabBarValuesX on ExportWatchOnlyTabBarValues {
  bool get isBitcoin => this == ExportWatchOnlyTabBarValues.bitcoin;
  bool get isLiquid => this == ExportWatchOnlyTabBarValues.liquid;
}

enum PriceSourceExtra { usd, eur, cad }

enum LoadBitcoinChipTabBar { csv, manual }

extension LoadBitcoinChipTabBarX on LoadBitcoinChipTabBar {
  bool get isCsv => this == LoadBitcoinChipTabBar.csv;
  bool get isManual => this == LoadBitcoinChipTabBar.manual;
}
