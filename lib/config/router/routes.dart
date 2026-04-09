import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/address_list/address_list_args.dart';
import 'package:aqua/features/address_list/address_list_screen.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/bip329/bip329_settings_screen.dart';
import 'package:aqua/features/settings/debug/debug_database_screen.dart';
import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:aqua/features/boltz/screens/boltz_swap_detail_screen.dart';
import 'package:aqua/features/boltz/screens/boltz_swaps_screen.dart';
import 'package:aqua/features/desktop/layout/layout.dart';
import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/lending/pages/contract_details_screen.dart';
import 'package:aqua/features/lending/pages/create_contract_screen.dart';
import 'package:aqua/features/lending/pages/loans_listings_screen.dart';
import 'package:aqua/features/lending/pages/repayment_screen.dart';
import 'package:aqua/features/lending/pages/withdraw_collateral_screen.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/logger_table/logger_table.dart';
import 'package:aqua/features/marketplace/pages/on_ramp_screen.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/pin/pin.dart';
import 'package:aqua/features/pin/pin_warning_screen.dart';
import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/rbf/rbf.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/sam_rock/pages/sam_rock_screen.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/debug/debug_wallet_auth_screen.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/settings/notifications/pages/notifications_settings_screen.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/screens/common/webview_screen.dart';
import 'package:ui_components/shared/constants/constants.dart';

List<RouteBase> get routes {
  if (isDesktop) {
    return [
      /// Desktop Home Screen as primary screen while development of it is in progress
      // GoRoute(
      //     path: LoggerScreen.routeName,
      //     builder: (context, state) => const LoggerScreen()),
      // GoRoute(
      //   path: AuthWrapper.routeName,
      //   builder: (context, state) => const AuthWrapper(),
      // ),
      // GoRoute(
      //   path: EnvSwitchScreen.routeName,
      //   builder: (context, state) => const EnvSwitchScreen(),
      // ),
      ShellRoute(
        builder: (context, state, child) => DefaultDesktopLayout(child: child),
        routes: [
          GoRoute(
            path: DesktopHomeScreen.routeName,
            builder: (context, state) => DesktopHomeScreen(
              showDialog: state.extra != null
                  ? state.extra as WalletOnboardingDialog?
                  : null,
            ),
          ),
          GoRoute(
            path: SettingsScreen.routeName,
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: MarketplaceMapScreen.routeName,
            builder: (context, state) => const MarketplaceMapScreen(),
          ),
          GoRoute(
            path: DolphinCardScreen.routeName,
            builder: (context, state) => const DolphinCardScreen(),
          ),
        ],
      ),

      GoRoute(
        path: OnboardingScreen.routePath,
        builder: (context, state) => const OnboardingScreen(),
        routes: [
          GoRoute(
            path: RestoreWalletScreen.routePath,
            builder: (context, state) => const RestoreWalletScreen(),
          ),
        ],
      ),
    ];
  }

  return [
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
      path: StoredWalletsScreen.routeName,
      builder: (context, state) => const StoredWalletsScreen(),
    ),
    GoRoute(
      path: RestartScreen.routeName,
      builder: (context, state) => const RestartScreen(),
    ),
    GoRoute(
      path: EditWalletScreen.routeName,
      builder: (context, state) => EditWalletScreen(
        wallet: state.extra as StoredWallet?,
      ),
    ),
    GoRoute(
      path: WebviewScreen.routeName,
      builder: (context, state) =>
          WebviewScreen(arguments: state.extra as WebviewArguments),
    ),
    GoRoute(
      path: OnRampScreen.routeName,
      builder: (context, state) => const OnRampScreen(),
    ),
    GoRoute(
      path: SplashScreen.routeName,
      builder: (context, state) => SplashScreen(tagline: state.extra as String),
    ),
    GoRoute(
      path: SplashScreenPreview.routeName,
      builder: (context, state) => const SplashScreenPreview(),
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
        path: SetupPinScreen.routeName,
        builder: (context, state) => const SetupPinScreen()),
    GoRoute(
        path: CheckPinScreen.routeName,
        builder: (context, state) =>
            CheckPinScreen(arguments: state.extra as CheckPinScreenArguments)),
    GoRoute(
      path: WalletPhraseWarningScreen.routeName,
      builder: (context, state) => WalletPhraseWarningScreen(
        arguments: (state.extra as RecoveryPhraseScreenArguments?) ??
            const RecoveryPhraseScreenArguments(),
      ),
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
      path: WalletRestoreReviewScreen.routeName,
      builder: (context, state) => const WalletRestoreReviewScreen(),
    ),
    GoRoute(
      path: HomeScreen.routeName,
      builder: (context, state) => const HomeScreen(),
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
      path: LanguageSettingsScreen.routeName,
      builder: (context, state) => const LanguageSettingsScreen(),
    ),
    GoRoute(
      path: RegionSettingsScreen.routeName,
      builder: (context, state) {
        final isFromMarketplace = state.extra as bool;
        return RegionSettingsScreen(isFromMarketplace: isFromMarketplace);
      },
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
      path: PriceSourceScreen.routeName,
      builder: (context, state) => PriceSourceScreen(
        exchangeRate: state.extra as ExchangeRate,
      ),
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
      path: AutoLockSettingsScreen.routeName,
      builder: (context, state) => const AutoLockSettingsScreen(),
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
      path: AssetTransactionsScreen.routeName,
      builder: (context, state) =>
          AssetTransactionsScreen(asset: state.extra as Asset),
    ),
    GoRoute(
      path: AssetTransactionDetailsScreen.routeName,
      builder: (context, state) => AssetTransactionDetailsScreen(
        args: state.extra as TransactionDetailsArgs,
      ),
    ),
    GoRoute(
      path: PokerchipScreen.routeName,
      builder: (context, state) => const PokerchipScreen(),
    ),
    GoRoute(
      path: SecuritySettingsScreen.routeName,
      builder: (context, state) => const SecuritySettingsScreen(),
    ),
    GoRoute(
      path: NotificationsSettingsScreen.routeName,
      builder: (context, state) => const NotificationsSettingsScreen(),
    ),
    GoRoute(
      path: AdvancedSettingsScreen.routeName,
      builder: (context, state) => const AdvancedSettingsScreen(),
    ),
    GoRoute(
      path: WalletSettingsScreen.routeName,
      builder: (_, state) => WalletSettingsScreen(
        walletId: state.extra as String,
      ),
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
      path: SendAssetTransactionCompleteScreen.routeName,
      builder: (context, state) => SendAssetTransactionCompleteScreen(
        args: state.extra as TransactionSuccessArguments,
      ),
    ),
    GoRoute(
      path: SendAssetScreen.routeName,
      builder: (context, state) =>
          SendAssetScreen(arguments: state.extra as SendAssetArguments),
    ),
    GoRoute(
      path: AssetTransactionSuccessScreen.routeName,
      builder: (context, state) => AssetTransactionSuccessScreen(
        args: state.extra as TransactionSuccessArguments,
      ),
    ),
    GoRoute(
      path: CustomFeeInputScreen.routeName,
      builder: (context, state) => CustomFeeInputScreen(
        args: state.extra as CustomFeeInputScreenArguments,
      ),
    ),
    GoRoute(
      path: ReceiveMenuScreen.routeName,
      builder: (context, state) => const ReceiveMenuScreen(),
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
          BoltzSwapDetailScreen(swap: state.extra as BoltzSwapDbModel),
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
      path: DebugDatabaseScreen.routeName,
      builder: (context, state) => const DebugDatabaseScreen(),
    ),
    GoRoute(
      path: LegacyWalletScreen.routeName,
      builder: (context, state) => const LegacyWalletScreen(),
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
      path: SendMenuScreen.routeName,
      builder: (context, state) => const SendMenuScreen(),
    ),
    GoRoute(
      path: SendAssetScreen.routeName,
      builder: (context, state) =>
          SendAssetScreen(arguments: state.extra as SendAssetArguments),
    ),
    GoRoute(
      path: RbfFeeInputScreen.routeName,
      builder: (_, state) =>
          RbfFeeInputScreen(transactionId: state.extra as String),
    ),
    GoRoute(
      path: SubaccountsDebugScreen.routeName,
      builder: (context, state) => const SubaccountsDebugScreen(),
    ),
    GoRoute(
      path: DebugWalletAuthScreen.routeName,
      builder: (context, state) => const DebugWalletAuthScreen(),
    ),
    GoRoute(
      path: Jan3LoginScreen.routeName,
      // NOTE: name is required for the redirect logic to work.
      name: Jan3LoginScreen.routeName,
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
    GoRoute(
      path: ReceiveAmountScreen.routeName,
      builder: (context, state) => ReceiveAmountScreen(
        args: state.extra as ReceiveAmountArguments,
      ),
    ),
    GoRoute(
      path: UnitCurrencySelectionScreen.routeName,
      builder: (context, state) => UnitCurrencySelectionScreen(
        args: state.extra as UnitCurrencySelectionArguments,
      ),
    ),
    GoRoute(
      path: LoansListingsScreen.routeName,
      builder: (context, state) => const LoansListingsScreen(),
    ),
    GoRoute(
      path: CreateContractScreen.routeName,
      builder: (context, state) => const CreateContractScreen(),
    ),
    GoRoute(
      path: ContractDetailsScreen.routeName,
      builder: (context, state) => const ContractDetailsScreen(),
    ),
    GoRoute(
      path: RepaymentScreen.routeName,
      builder: (context, state) => const RepaymentScreen(),
    ),
    GoRoute(
      path: WithdrawCollateralScreen.routeName,
      builder: (context, state) => const WithdrawCollateralScreen(),
    ),
    GoRoute(
      path: AssetNetworkSelectionScreen.routeName,
      builder: (context, state) => AssetNetworkSelectionScreen(
        filterAsset: state.extra as Asset?,
      ),
    ),
    GoRoute(
      path: ServiceErrorScreen.routeName,
      builder: (context, state) => const ServiceErrorScreen(),
    ),
  ];
}
