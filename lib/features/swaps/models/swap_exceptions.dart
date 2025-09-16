import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:flutter/widgets.dart';
import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/features/shared/shared.dart';

abstract class SwapServiceException implements ExceptionLocalized {
  final String? swapType;

  SwapServiceException([this.swapType]);
}

class SwapServiceGeneralException extends SwapServiceException {
  SwapServiceGeneralException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceGeneralError(swapType!)
        : context.loc.genericSwapError;
  }
}

class SwapServiceApiException extends SwapServiceException {
  SwapServiceApiException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceApiError(swapType!)
        : context.loc.genericSwapApiError;
  }
}

class SwapServiceAuthenticationException extends SwapServiceException {
  SwapServiceAuthenticationException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceAuthenticationError(swapType!)
        : context.loc.genericSwapAuthError;
  }
}

class SwapServiceCurrencyListException extends SwapServiceException {
  SwapServiceCurrencyListException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceCurrencyListError(swapType!)
        : context.loc.genericSwapCurrencyListError;
  }
}

class SwapServicePairsFetchException extends SwapServiceException {
  SwapServicePairsFetchException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServicePairsFetchError(swapType!)
        : context.loc.genericSwapPairsError;
  }
}

class SwapServiceQuoteException extends SwapServiceException {
  SwapServiceQuoteException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceQuoteError(swapType!)
        : context.loc.genericSwapQuoteError;
  }
}

class SwapServiceAmountException extends SwapServiceException {
  SwapServiceAmountException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.genericSwapAmountError;
  }
}

class SwapServiceOrderCreationException extends SwapServiceException {
  SwapServiceOrderCreationException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceOrderCreationError(swapType!)
        : context.loc.genericSwapOrderCreationError;
  }
}

class SwapServiceOrderStatusException extends SwapServiceException {
  SwapServiceOrderStatusException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceOrderStatusError(swapType!)
        : context.loc.genericSwapOrderStatusError;
  }
}

class SwapServiceMinAmountException extends SwapServiceException {
  SwapServiceMinAmountException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceMinAmountError(swapType!)
        : context.loc.genericSwapMinAmountError;
  }
}

class SwapServiceMaxAmountException extends SwapServiceException {
  SwapServiceMaxAmountException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceMaxAmountError(swapType!)
        : context.loc.genericSwapMaxAmountError;
  }
}

class SwapServiceUnsupportedCurrencyException extends SwapServiceException {
  SwapServiceUnsupportedCurrencyException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceUnsupportedCurrencyError(swapType!)
        : context.loc.genericSwapUnsupportedCurrencyError;
  }
}

class SwapServiceInvalidAddressException extends SwapServiceException {
  SwapServiceInvalidAddressException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceInvalidAddressError(swapType!)
        : context.loc.genericSwapInvalidAddressError;
  }
}

class SwapServiceNetworkFeeException extends SwapServiceException {
  SwapServiceNetworkFeeException([super.swapType]);

  @override
  String toLocalizedString(BuildContext context) {
    return swapType?.isNotEmpty == true
        ? context.loc.swapServiceNetworkFeeError(swapType!)
        : context.loc.genericSwapNetworkFeeError;
  }
}
