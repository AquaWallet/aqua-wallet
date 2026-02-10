import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class AssetTransactionsInvalidTypeException implements Exception {}

class AssetTransactionDetailsInvalidArgumentsException implements Exception {}

class AssetTransactionDetailsTransactionNotFoundException
    implements Exception {}

class AssetTransactionDetailsProviderUnableToLaunchLinkException
    implements Exception {}

class AssetTransactionNotFoundException implements ExceptionLocalized {
  @override
  String toLocalizedString(BuildContext context) =>
      context.loc.feeNotFoundError;
}
