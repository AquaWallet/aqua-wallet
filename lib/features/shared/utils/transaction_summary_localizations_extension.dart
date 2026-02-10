import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ui_components/components/transaction/transaction_summary_text.dart';

extension TransactionSummaryLocalizationsExtension on AppLocalizations {
  /// Provides [TransactionSummaryText] from [AppLocalizations].
  TransactionSummaryText get transactionSummaryLocalizations =>
      TransactionSummaryText(
        from: from,
        to: to,
      );
}
