import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:ui_components/components/debit_card/debit_card_text.dart';

extension DebitCardLocalizationsExtension on AppLocalizations {
  /// Provides [DebitCardLocalizations] from [AppLocalizations].
  DebitCardText get debitCardLocalizations => DebitCardText(
        reloadable: reloadable,
        nonReloadable: commonNonReloadable,
        expiryDate: expiryDate,
        cvv: cvv,
      );
}
