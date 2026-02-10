import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ui_components/components/wallet_header/wallet_header_text.dart';

extension WalletHeaderLocalizationsExtension on AppLocalizations {
  /// Provides [WalletHeaderText] from [AppLocalizations].
  WalletHeaderText get walletHeaderLocalizations => WalletHeaderText(
        receive: receive,
        send: send,
        scan: scan,
        bitcoinPrice: bitcoinPrice,
      );
}
