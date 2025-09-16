import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/widgets.dart';
import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/features/shared/shared.dart';

class SubaccountException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.generalError;
  }
}

class SubaccountCreationException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.subaccountCreationError;
  }
}

class SubaccountUpdateException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.subaccountUpdateError;
  }
}

class SubaccountUpdateMainAccountNameException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.subaccountUpdateMainAccountNameError;
  }
}

class SubaccountNotFoundException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.subaccountNotFoundError;
  }
}

class SubaccountLoadException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.subaccountLoadError;
  }
}

class InvalidNetworkTypeException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.invalidNetworkTypeError;
  }
}

class InvalidSubaccountTypeException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.invalidSubaccountTypeError;
  }
}

class TransactionFetchException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.transactionFetchError;
  }
}

class NativeSegwitSubaccountCreationException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.nativeSegwitSubaccountCreationError;
  }
}

class LegacySegwitSubaccountNotFoundException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.legacySegwitSubaccountNotFoundError;
  }
}

//TODO: These should be moved to transaction feature
class ReceiveAddressException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.receiveAddressError;
  }
}

class NoUnspentOutputsException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.noUnspentOutputsError;
  }
}

class TransactionCreationException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.transactionCreationError;
  }
}

class TransactionSigningException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.transactionSigningError;
  }
}

class TransactionBroadcastException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.transactionBroadcastError;
  }
}

class TransactionBlindingException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.transactionBlindingError;
  }
}
