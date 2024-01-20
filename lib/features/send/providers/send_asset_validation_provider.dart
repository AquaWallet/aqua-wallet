import 'package:aqua/common/errors/error_localized.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_asset_validation_provider.g.dart';

enum SendAssetValidationException implements Exception, ErrorLocalized {
  emptyAmount,
  invoiceIsEmpty,
  notEnoughFunds,
  emptyAddress,
  emptyAddressLightning,
  invalidAddress,
  unsupportedInvoice,
  expiredInvoice,
  nonMatchingAssetId;

  @override
  String toLocalizedString(BuildContext context) {
    switch (this) {
      case SendAssetValidationException.emptyAddress:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenEmptyAddressError;
      case SendAssetValidationException.invoiceIsEmpty:
        return AppLocalizations.of(context)!
            .sendAssetScreenLightningZeroSatsErrorMessage;
      case SendAssetValidationException.emptyAddressLightning:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenLightningEmptyAddressError;
      case SendAssetValidationException.emptyAmount:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenEmptyAmountError;
      case SendAssetValidationException.invalidAddress:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenInvalidAddressError;
      case SendAssetValidationException.notEnoughFunds:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenNotEnoughFundsError;
      case SendAssetValidationException.unsupportedInvoice:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenUnsupportedInvoiceError;
      case SendAssetValidationException.expiredInvoice:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenExpiredInvoiceError;
      case SendAssetValidationException.nonMatchingAssetId:
        return AppLocalizations.of(context)!
            .sendAssetAmountScreenNonMatchingAssetIdError;
      default:
        throw ('Unhandled validation error');
    }
  }
}

@riverpod
Future<bool> sendAssetValidation(SendAssetValidationRef ref,
    {required SendAssetValidationParams params}) async {
  if (params.address == null || params.address!.isEmpty) {
    params.asset.isLightning
        ? throw SendAssetValidationException.emptyAddressLightning
        : throw SendAssetValidationException.emptyAddress;
  }
  if (params.asset.isLightning &&
      params.asset.shouldDisableEditAmountOnSend &&
      params.amount == 0) {
    throw SendAssetValidationException.invoiceIsEmpty;
  }

  final isValidAddress = await ref
      .read(addressParserProvider)
      .isValidAddressForAsset(address: params.address!, asset: params.asset);

  if (!isValidAddress) {
    throw SendAssetValidationException.invalidAddress;
  }

  if (params.amount == null || params.amount! <= 0) {
    throw SendAssetValidationException.emptyAmount;
  }
  if (params.balance == null || params.amount! > params.balance!) {
    throw SendAssetValidationException.notEnoughFunds;
  }

  return true;
}
