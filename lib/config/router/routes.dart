import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/address_list/address_list_args.dart';
import 'package:aqua/features/address_list/address_list_screen.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/bip329/bip329_settings_screen.dart';
import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:aqua/features/boltz/screens/boltz_swap_detail_screen.dart';
import 'package:aqua/features/boltz/screens/boltz_swaps_screen.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/logger_table/logger_table.dart';
import 'package:aqua/features/marketplace/pages/on_ramp_screen.dart';
import 'package:aqua/features/note/note.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/pin/pin_screen.dart';
import 'package:aqua/features/pin/pin_success_screen.dart';
import 'package:aqua/features/pin/pin_warning_screen.dart';
import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/recovery/pages/warning_phrase_screen.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/sam_rock/pages/sam_rock_screen.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/pages/address_selection_screen.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/shared/pages/themes_settings_screen.dart';
import 'package:aqua/features/settings/watch_only/watch_only.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/pages/swap_order_detail_screen.dart';
import 'package:aqua/features/swaps/pages/swap_orders_screen.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:go_router/go_router.dart';

final routes = [
  GoRoute(
      path: LoggerScreen.routeName,
      builder: (context, state) => const LoggerScreen()),
  GoRoute(
    path: AuthWrapper.routeName,
    builder: (context, state) => const AuthWrapper(),
  ),
  GoRoute(
    path: EnvSwitchScreen.routeName,
    builder: (context, state) => const EnvSwitchScreen(),
  ),
  GoRoute(
    path: WebviewScreen.routeName,
    builder: (context, state) =>
        WebviewScreen(arguments: state.extra as WebviewArguments),
  ),
  GoRoute(
    path: RefundScreen.routeName,
    builder: (context, state) =>
        RefundScreen(arguments: state.extra as RefundArguments),
  ),
  GoRoute(
    path: OnRampScreen.routeName,
    builder: (context, state) => const OnRampScreen(),
  ),
  GoRoute(
    path: SplashScreen.routeName,
    builder: (context, state) => const SplashScreen(),
  ),
  GoRoute(
    path: WelcomeScreen.routeName,
    builder: (context, state) => const WelcomeScreen(),
  ),
  GoRoute(
    path: WalletBackupScreen.routeName,
    builder: (context, state) => const WalletBackupScreen(),
  ),
  GoRoute(
    path: WalletBackupConfirmation.routeName,
    builder: (context, state) => const WalletBackupConfirmation(),
  ),
  GoRoute(
    path: WalletRestoreScreen.routeName,
    builder: (context, state) => const WalletRestoreScreen(),
  ),
  GoRoute(
    path: WalletRecoveryPhraseScreen.routeName,
    builder: (context, state) => WalletRecoveryPhraseScreen(
        arguments: state.extra as RecoveryPhraseScreenArguments),
  ),
  GoRoute(
      path: PinWarningScreen.routeName,
      builder: (context, state) => const PinWarningScreen()),
  GoRoute(
      path: PinSuccessScreen.routeName,
      builder: (context, state) => const PinSuccessScreen()),
  GoRoute(
      path: SetupPinScreen.routeName,
      builder: (context, state) => const SetupPinScreen()),
  GoRoute(
      path: CheckPinScreen.routeName,
      builder: (context, state) =>
          CheckPinScreen(arguments: state.extra as CheckPinScreenArguments)),
  GoRoute(
    path: WalletPhraseWarningScreen.routeName,
    builder: (context, state) => const WalletPhraseWarningScreen(),
  ),
  GoRoute(
    path: WalletRecoveryQRScreen.routeName,
    builder: (context, state) => const WalletRecoveryQRScreen(),
  ),
  GoRoute(
    path: WalletRestoreInputScreen.routeName,
    builder: (context, state) => const WalletRestoreInputScreen(),
  ),
  GoRoute(
    path: HomeScreen.routeName,
    builder: (context, state) => const HomeScreen(),
  ),
  GoRoute(
    path: WalletBackupConfirmationFailure.routeName,
    builder: (context, state) => const WalletBackupConfirmationFailure(),
  ),
  GoRoute(
    path: SwapScreen.routeName,
    builder: (context, state) => const SwapScreen(),
  ),
  GoRoute(
    path: SwapReviewScreen.routeName,
    builder: (context, state) => SwapReviewScreen(arg: state.extra),
  ),
  GoRoute(
    path: SwapAssetCompleteScreen.routeName,
    builder: (context, state) =>
        SwapAssetCompleteScreen(arguments: state.extra as SwapStateSuccess),
  ),
  GoRoute(
    path: QrScannerScreen.routeName,
    builder: (context, state) =>
        QrScannerScreen(arguments: state.extra as QrScannerArguments),
  ),
  GoRoute(
    path: TextScannerScreen.routeName,
    builder: (context, state) => TextScannerScreen(
      arguments: state.extra as TextScannerArguments,
    ),
  ),
  GoRoute(
    path: ScanScreen.routeName,
    builder: (context, state) {
      final args = state.extra as ScanArguments;
      return ScanScreen(arguments: args);
    },
  ),
  GoRoute(
    path: AddressSelectionScreen.routeName,
    builder: (context, state) {
      final addresses = state.extra as List<String>;
      return AddressSelectionScreen(addresses: addresses);
    },
  ),
  GoRoute(
    path: AddNoteScreen.routeName,
    builder: (context, state) => const AddNoteScreen(),
  ),
  GoRoute(
    path: LanguageSettingsScreen.routeName,
    builder: (context, state) => const LanguageSettingsScreen(),
  ),
  GoRoute(
    path: RegionSettingsScreen.routeName,
    builder: (context, state) => const RegionSettingsScreen(),
  ),
  GoRoute(
    path: NotesSettingsScreen.routeName,
    builder: (context, state) => const NotesSettingsScreen(),
  ),
  GoRoute(
    path: ExchangeRateSettingsScreen.routeName,
    builder: (context, state) => const ExchangeRateSettingsScreen(),
  ),
  GoRoute(
    path: ConversionCurrenciesSettingsScreen.routeName,
    builder: (context, state) => const ConversionCurrenciesSettingsScreen(),
  ),
  GoRoute(
    path: ThemesSettingsScreen.routeName,
    builder: (context, state) => const ThemesSettingsScreen(),
  ),
  GoRoute(
    path: BlockExplorerSettingsScreen.routeName,
    builder: (context, state) => const BlockExplorerSettingsScreen(),
  ),
  GoRoute(
    path: ElectrumServerSettingsScreen.routeName,
    builder: (context, state) => const ElectrumServerSettingsScreen(),
  ),
  GoRoute(
    path: DisplayUnitsSettingsScreen.routeName,
    builder: (context, state) => const DisplayUnitsSettingsScreen(),
  ),
  GoRoute(
    path: ManageAssetsScreen.routeName,
    builder: (context, state) => const ManageAssetsScreen(),
  ),
  GoRoute(
    path: AddAssetsScreen.routeName,
    builder: (context, state) => const AddAssetsScreen(),
  ),
  GoRoute(
    path: RemoveWalletConfirmScreen.routeName,
    builder: (context, state) => const RemoveWalletConfirmScreen(),
  ),
  GoRoute(
    path: AssetTransactionsScreen.routeName,
    builder: (context, state) =>
        AssetTransactionsScreen(asset: state.extra as Asset),
  ),
  GoRoute(
    path: AssetTransactionDetailsScreen.routeName,
    builder: (context, state) => AssetTransactionDetailsScreen(
        arguments: state.extra as TransactionUiModel),
  ),
  GoRoute(
    path: PokerchipScreen.routeName,
    builder: (context, state) => const PokerchipScreen(),
  ),
  GoRoute(
    path: PokerchipScannerScreen.routeName,
    builder: (context, state) => const PokerchipScannerScreen(),
  ),
  GoRoute(
    path: PokerchipBalanceScreen.routeName,
    builder: (context, state) =>
        PokerchipBalanceScreen(address: state.extra as String),
  ),
  GoRoute(
    path: TransactionMenuScreen.routeName,
    builder: (context, state) =>
        TransactionMenuScreen(type: state.extra as TransactionType),
  ),
  GoRoute(
    path: SendAssetTransactionCompleteScreen.routeName,
    builder: (context, state) => SendAssetTransactionCompleteScreen(
      args: state.extra as SendAssetCompletionArguments,
    ),
  ),
  GoRoute(
    path: SendAssetScreen.routeName,
    builder: (context, state) =>
        SendAssetScreen(arguments: state.extra as SendAssetArguments),
  ),
  GoRoute(
    path: ReceiveAssetScreen.routeName,
    builder: (context, state) =>
        ReceiveAssetScreen(arguments: state.extra as ReceiveArguments),
  ),
  GoRoute(
    path: BoltzSwapsScreen.routeName,
    builder: (context, state) => const BoltzSwapsScreen(),
  ),
  GoRoute(
    path: BoltzSwapDetailScreen.routeName,
    builder: (context, state) =>
        BoltzSwapDetailScreen(swapData: state.extra as BoltzSwapDbModel),
  ),
  GoRoute(
    path: LightningTransactionSuccessScreen.routeName,
    builder: (context, state) => LightningTransactionSuccessScreen(
        arguments: state.extra as LightningSuccessArguments),
  ),
  GoRoute(
    path: LnurlWithdrawScreen.routeName,
    builder: (context, state) =>
        LnurlWithdrawScreen(arguments: state.extra as LNURLWithdrawParams),
  ),
  GoRoute(
    path: HelpSupportScreen.routeName,
    builder: (context, state) => const HelpSupportScreen(),
  ),
  GoRoute(
    path: ExperimentalFeaturesScreen.routeName,
    builder: (context, state) => const ExperimentalFeaturesScreen(),
  ),
  GoRoute(
    path: InternalSendAmountScreen.routeName,
    builder: (context, state) => InternalSendAmountScreen(
        arguments: state.extra as InternalSendAmountArguments),
  ),
  GoRoute(
    path: InternalSendReviewScreen.routeName,
    builder: (context, state) => InternalSendReviewScreen(
        arguments: state.extra as InternalSendArguments),
  ),
  GoRoute(
    path: InternalSendCompleteScreen.routeName,
    builder: (context, state) => InternalSendCompleteScreen(
        arguments: state.extra as InternalSendArguments),
  ),
  GoRoute(
    path: DirectPegInScreen.routeName,
    builder: (context, state) => const DirectPegInScreen(),
  ),
  GoRoute(
    path: AddressListScreen.routeName,
    builder: (context, state) =>
        AddressListScreen(args: state.extra as AddressListArgs),
  ),
  GoRoute(
    path: WatchOnlyListScreen.routeName,
    builder: (context, state) => const WatchOnlyListScreen(),
  ),
  GoRoute(
    path: WatchOnlyDetailScreen.routeName,
    builder: (context, state) =>
        WatchOnlyDetailScreen(wallet: state.extra as Subaccount),
  ),
  GoRoute(
    path: SwapOrdersScreen.routeName,
    builder: (context, state) => const SwapOrdersScreen(),
  ),
  GoRoute(
    path: SwapOrderDetailScreen.routeName,
    builder: (context, state) =>
        SwapOrderDetailScreen(order: state.extra as SwapOrderDbModel),
  ),
  GoRoute(
    path: SendAssetScreen.routeName,
    builder: (context, state) =>
        SendAssetScreen(arguments: state.extra as SendAssetArguments),
  ),
  GoRoute(
    path: SubaccountsDebugScreen.routeName,
    builder: (context, state) => const SubaccountsDebugScreen(),
  ),
  GoRoute(
    path: Jan3LoginScreen.routeName,
    builder: (context, state) => const Jan3LoginScreen(),
  ),
  GoRoute(
    path: Jan3OtpVerificationScreen.routeName,
    builder: (_, state) => Jan3OtpVerificationScreen(
      email: state.extra as String,
    ),
  ),
  GoRoute(
    path: DebitCardOnboardingScreen.routeName,
    builder: (context, state) => const DebitCardOnboardingScreen(),
  ),
  GoRoute(
    path: DebitCardMyCardScreen.routeName,
    builder: (context, state) => const DebitCardMyCardScreen(),
  ),
  GoRoute(
    path: DebitCardTopUpScreen.routeName,
    builder: (context, state) => const DebitCardTopUpScreen(),
  ),
  GoRoute(
    path: DebitCardStyleSelectionScreen.routeName,
    builder: (context, state) => const DebitCardStyleSelectionScreen(),
  ),
  GoRoute(
    path: SamRockScreen.routeName,
    builder: (context, state) => SamRockScreen(
      samRockAppLink: state.extra as SamRockAppLink,
    ),
  ),
];
