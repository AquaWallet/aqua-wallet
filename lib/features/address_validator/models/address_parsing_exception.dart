import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class AddressParsingException implements ExceptionLocalized {
  final AddressParsingExceptionType type;
  final String? customMessage;
  final String? amountInSats;

  AddressParsingException(this.type, {this.customMessage, this.amountInSats});

  @override
  String toLocalizedString(
    BuildContext context,
  ) {
    switch (type) {
      case AddressParsingExceptionType.emptyAddress:
        return context.loc.sendAssetAmountScreenEmptyAddressError;
      case AddressParsingExceptionType.invalidAddress:
        return context.loc.invalidAddress;
      case AddressParsingExceptionType.unsupportedInvoice:
        return context.loc.sendAssetAmountScreenUnsupportedInvoiceError;
      case AddressParsingExceptionType.expiredInvoice:
        return context.loc.sendAssetAmountScreenExpiredInvoiceError;
      case AddressParsingExceptionType.noAmountInInvoice:
        return context.loc.invoicesWithoutAmountNotSupported;
      case AddressParsingExceptionType.lessThanMinAmountInInvoice:
        return context.loc
            .sendAssetAmountScreenLessThanMinAmountError(amountInSats ?? '0');
      case AddressParsingExceptionType.greaterThanMaxAmountInInvoice:
        return context.loc.sendAssetAmountScreenGreaterThanMaxAmountError;
      case AddressParsingExceptionType.invalidLightningAddress:
        return context.loc.sendAssetAmountScreenInvalidLightningAddressError;
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
  lessThanMinAmountInInvoice,
  greaterThanMaxAmountInInvoice,
  invalidLightningAddress,
  boltzInvoiceError,
  nonMatchingAmountInInvoice,
  nonMatchingAssetId,
  assetNotInManagedAssets,
  generic;
}
