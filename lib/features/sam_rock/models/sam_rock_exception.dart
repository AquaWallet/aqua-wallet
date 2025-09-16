import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';

class SamRockException implements ExceptionLocalized {
  final SamRockExceptionType type;
  final String? customMessage;

  SamRockException(this.type, {this.customMessage});

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case SamRockExceptionType.notEnoughSubaccounts:
        return context.loc.samrock_not_enough_subaccounts_exception;
      case SamRockExceptionType.connectionFailed:
        return context.loc.samrock_connection_failed_exception;
      case SamRockExceptionType.missingWalletData:
        return context.loc.samrock_missing_wallet_data_exception;
      case SamRockExceptionType.failedToGetNewWalletState:
        return context.loc.samRockFailedToGetNewWalletStateException;
      case SamRockExceptionType.generic:
        return customMessage ?? context.loc.samrock_generic_exception;
    }
  }
}

enum SamRockExceptionType {
  notEnoughSubaccounts,
  connectionFailed,
  missingWalletData,
  failedToGetNewWalletState,
  generic,
}
