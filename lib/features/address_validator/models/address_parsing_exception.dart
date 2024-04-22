import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class AddressParsingException implements ExceptionLocalized {
  final AddressParsingExceptionType type;
  final String? customMessage;

  AddressParsingException(this.type, {this.customMessage});

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case AddressParsingExceptionType.emptyAddress:
        return context.loc.sendAssetAmountScreenEmptyAddressError;
      case AddressParsingExceptionType.invalidAddress:
        return context.loc.sendAssetAmountScreenInvalidAddressError;
      case AddressParsingExceptionType.unsupportedInvoice:
        return context.loc.sendAssetAmountScreenUnsupportedInvoiceError;
      case AddressParsingExceptionType.expiredInvoice:
        return context.loc.sendAssetAmountScreenExpiredInvoiceError;
      case AddressParsingExceptionType.noAmountInInvoice:
        return context.loc.sendAssetAmountScreenNoAmountInnvoiceError;
      case AddressParsingExceptionType.boltzInvoiceError:
        return context.loc.sendAssetAmountScreenBoltzInvoiceError;
      case AddressParsingExceptionType.nonMatchingAmountInInvoice:
        return context.loc.sendAssetAmountScreenNonMatchingAmountError;
      case AddressParsingExceptionType.nonMatchingAssetId:
        return context.loc.sendAssetAmountScreenNonMatchingAssetIdError;
      case AddressParsingExceptionType.assetNotInManagedAssets:
        return context.loc.sendAssetAmountScreenAssetNotInManagedAssetsError;
      case AddressParsingExceptionType.generic:
        return customMessage ?? toString();
      default:
        throw ('Unhandled validation error');
    }
  }
}

enum AddressParsingExceptionType {
  emptyAddress,
  invalidAddress,
  unsupportedInvoice,
  expiredInvoice,
  noAmountInInvoice,
  boltzInvoiceError,
  nonMatchingAmountInInvoice,
  nonMatchingAssetId,
  assetNotInManagedAssets,
  generic;
}
