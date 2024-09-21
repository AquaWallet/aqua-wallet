import 'package:aqua/features/address_list/address_list_screen.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/boltz/screens/boltz_swap_detail_screen.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/marketplace/pages/on_ramp_screen.dart';
import 'package:aqua/features/note/note.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/onboarding/welcome/widgets/welcome_disclaimer_screen.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/exchange_rate/pages/currency_conversion_settings_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/features/transactions/pages/pages.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:aqua/screens/qrscanner/qr_scanner_screen.dart';

import 'features/boltz/screens/boltz_swaps_screen.dart';

mixin Routes {
  static final Map<String,
      MaterialPageRoute<Object> Function(RouteSettings settings)> pages = {
    EnvSwitchScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const EnvSwitchScreen(),
          settings: settings,
        ),
    WebviewScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WebviewScreen(),
          settings: settings,
        ),
    RefundScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const RefundScreen(),
          settings: settings,
        ),
    OnRampScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const OnRampScreen(),
          settings: settings,
        ),
    SplashScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const SplashScreen(),
          settings: settings,
        ),
    WelcomeScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WelcomeScreen(),
          settings: settings,
        ),
    WelcomeDisclaimerScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WelcomeDisclaimerScreen(),
          settings: settings,
        ),
    WalletBackupScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WalletBackupScreen(),
          settings: settings,
        ),
    WalletBackupConfirmation.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WalletBackupConfirmation(),
          settings: settings,
        ),
    WalletRestoreScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WalletRestoreScreen(),
          settings: settings,
        ),
    WalletRecoveryPhraseScreen.routeName: (settings) =>
        MaterialPageRoute<Object>(
          builder: (context) => const WalletRecoveryPhraseScreen(),
          settings: settings,
        ),
    WalletRecoveryQRScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WalletRecoveryQRScreen(),
          settings: settings,
        ),
    WalletRestoreInputScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const WalletRestoreInputScreen(),
          settings: settings,
        ),
    HomeScreen.routeName: (settings) => MaterialPageRoute<Object>(
          builder: (context) => const HomeScreen(),
          settings: settings,
        ),
    WalletBackupConfirmationFailure.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const WalletBackupConfirmationFailure(),
        settings: settings,
      );
    },
    SwapScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SwapScreen(),
        settings: settings,
      );
    },
    SwapReviewScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SwapReviewScreen(),
        settings: settings,
      );
    },
    SwapAssetCompleteScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SwapAssetCompleteScreen(),
        settings: settings,
      );
    },
    QrScannerScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const QrScannerScreen(),
        settings: settings,
      );
    },
    AddNoteScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const AddNoteScreen(),
        settings: settings,
      );
    },
    LanguageSettingsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const LanguageSettingsScreen(),
        settings: settings,
      );
    },
    RegionSettingsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const RegionSettingsScreen(),
        settings: settings,
      );
    },
    ExchangeRateSettingsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const ExchangeRateSettingsScreen(),
        settings: settings,
      );
    },
    ConversionCurrenciesSettingsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const ConversionCurrenciesSettingsScreen(),
        settings: settings,
      );
    },
    BlockExplorerSettingsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const BlockExplorerSettingsScreen(),
        settings: settings,
      );
    },
    ManageAssetsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const ManageAssetsScreen(),
        settings: settings,
      );
    },
    AddAssetsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const AddAssetsScreen(),
        settings: settings,
      );
    },
    RemoveWalletConfirmScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const RemoveWalletConfirmScreen(),
        settings: settings,
      );
    },
    AssetTransactionsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const AssetTransactionsScreen(),
        settings: settings,
      );
    },
    AssetTransactionDetailsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const AssetTransactionDetailsScreen(),
        settings: settings,
      );
    },
    PokerchipScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const PokerchipScreen(),
        settings: settings,
      );
    },
    PokerchipScannerScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const PokerchipScannerScreen(),
        settings: settings,
      );
    },
    PokerchipBalanceScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const PokerchipBalanceScreen(),
        settings: settings,
      );
    },
    TransactionMenuScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const TransactionMenuScreen(),
        settings: settings,
      );
    },
    SendAssetContainerScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SendAssetContainerScreen(),
        settings: settings,
      );
    },
    SendAssetAddressScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SendAssetAddressScreen(),
        settings: settings,
      );
    },
    SendAssetAmountScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SendAssetAmountScreen(),
        settings: settings,
      );
    },
    SendAssetReviewScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SendAssetReviewScreen(),
        settings: settings,
      );
    },
    SendAssetTransactionCompleteScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SendAssetTransactionCompleteScreen(),
        settings: settings,
      );
    },
    ReceiveAssetScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const ReceiveAssetScreen(),
        settings: settings,
      );
    },
    SideShiftOrdersScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SideShiftOrdersScreen(),
        settings: settings,
      );
    },
    SideshiftOrderDetailScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const SideshiftOrderDetailScreen(),
        settings: settings,
      );
    },
    BoltzSwapsScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const BoltzSwapsScreen(),
        settings: settings,
      );
    },
    BoltzSwapDetailScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const BoltzSwapDetailScreen(),
        settings: settings,
      );
    },
    LightningTransactionSuccessScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const LightningTransactionSuccessScreen(),
        settings: settings,
      );
    },
    LnurlWithdrawScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const LnurlWithdrawScreen(),
        settings: settings,
      );
    },
    HelpSupportScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const HelpSupportScreen(),
        settings: settings,
      );
    },
    ExperimentalFeaturesScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const ExperimentalFeaturesScreen(),
        settings: settings,
      );
    },
    InternalSendAmountScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const InternalSendAmountScreen(),
        settings: settings,
      );
    },
    InternalSendReviewScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const InternalSendReviewScreen(),
        settings: settings,
      );
    },
    InternalSendCompleteScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const InternalSendCompleteScreen(),
        settings: settings,
      );
    },
    DirectPegInScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const DirectPegInScreen(),
        settings: settings,
      );
    },
    AddressListScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const AddressListScreen(),
        settings: settings,
      );
    },
    WatchOnlyListScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const WatchOnlyListScreen(),
        settings: settings,
      );
    },
    WatchOnlyDetailScreen.routeName: (settings) {
      return MaterialPageRoute<Object>(
        builder: (context) => const WatchOnlyDetailScreen(),
        settings: settings,
      );
    },
  };
}
