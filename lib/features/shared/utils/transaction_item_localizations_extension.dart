import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ui_components/components/transaction/transaction_item_text.dart';

extension TransactionItemLocalizationsExtension on AppLocalizations {
  /// Provides [TransactionItemText] from [AppLocalizations].
  TransactionItemText get transactionItemLocalizations => TransactionItemText(
        failed: failed,
        insufficientFunds: insufficientFunds,
        addFunds: addFunds,
        redeposited: redeposited,
        refund: refund,
        toppingUp: toppingUp,
        sending: sending,
        sent: sent,
        receiving: receiving,
        received: received,
        swapping: swapping,
        swapped: swapped,
      );
}
