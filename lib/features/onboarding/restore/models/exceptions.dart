import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

enum WalletNameValidationExceptionType {
  empty,
  tooLong,
  duplicate,
}

class WalletNameValidationException implements ExceptionLocalized {
  final WalletNameValidationExceptionType type;

  const WalletNameValidationException(this.type);

  @override
  String toLocalizedString(BuildContext context) => switch (type) {
        WalletNameValidationExceptionType.duplicate =>
          context.loc.walletNameAlreadyExists,
        _ => context.loc.max23Characters,
      };
}

class WalletRestoreInvalidOptionsException implements Exception {}

class WalletRestoreInvalidMnemonicException implements Exception {}

class WalletRestoreConnectionFailureException implements Exception {}

class WalletRestoreException implements Exception {}

class WalletRestoreWalletAlreadyExistsException implements Exception {}
