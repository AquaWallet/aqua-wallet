class BTCDirectException implements Exception {
  final BTCDirectErrorCode code;
  final String? customMessage;

  BTCDirectException(this.code, {this.customMessage});

  factory BTCDirectException.fromResponse(Map<String, dynamic> response) {
    final errors = response['errors'] as Map<String, dynamic>?;
    if (errors == null || errors.isEmpty) {
      return BTCDirectException(BTCDirectErrorCode.unknown);
    }

    final firstError = errors.entries.first;
    final errorData = firstError.value as Map<String, dynamic>;
    final code = BTCDirectErrorCode.fromCode(errorData['code'] as String);
    final message = errorData['message'] as String?;

    return BTCDirectException(code, customMessage: message);
  }

  String get message => customMessage ?? code.defaultMessage;
}

enum BTCDirectErrorCode {
  // Input validation errors (300-339)
  blankBaseCurrency(
      'ER300', 'Base Currency should not be blank when Fixed Currency is set.'),
  invalidBaseCurrencyType('ER301', 'Base Currency should be a string.'),
  blankQuoteCurrency('ER302', 'Quote Currency should not be blank.'),
  invalidQuoteCurrencyType('ER303', 'Quote Currency should be a string.'),
  invalidBaseCurrencyAmount(
      'ER304', 'Base Currency Amount should be a number.'),
  invalidQuoteCurrencyAmount(
      'ER305', 'Quote Currency Amount should be a number.'),
  blankPaymentMethod('ER306',
      'Payment Method should not be blank when Fixed Payment Method is set.'),
  invalidPaymentMethodType('ER307', 'Payment Method should be a string.'),
  blankReturnUrl('ER308', 'Return URL should not be blank.'),
  invalidReturnUrlType('ER309', 'Return URL should be a string.'),
  invalidCallbackUrlType('ER310', 'Callback URL should be a string or null.'),
  invalidPartnerOrderId(
      'ER311', 'Partner Order Identifier should be a string or null.'),
  invalidWalletAddress('ER312', 'Wallet Address should be a string or null.'),
  invalidWalletAddressTag(
      'ER313', 'Wallet Address Tag should be a string or null.'),
  invalidExpireTime('ER314', 'Expire Time should be a int or null.'),
  invalidFee('ER315', 'Fee should be a number or null.'),
  invalidFixedAmount('ER316', 'Fixed Amount should be a boolean or null.'),
  invalidFixedCurrency('ER317', 'Fixed Currency should be a boolean or null.'),
  invalidFixedPaymentMethod(
      'ER318', 'Fixed Payment Method should be a boolean or null.'),
  invalidShowWalletAddress(
      'ER319', 'Show Wallet Address should be a boolean or null.'),
  invalidCurrencyAmountCombination('ER320',
      'Exactly one or none of baseCurrencyAmount or quoteCurrencyAmount must be set.'),
  blankCallbackUrl('ER321', 'Callback URL should not be blank.'),
  blankExpireTime('ER322', 'Expire Time should not be blank.'),
  blankFee('ER323', 'Fee should not be blank.'),
  generalError('ER324', 'Something went wrong.'),
  requiredWalletAddress('ER325', 'Wallet address is required'),
  invalidCurrencyPair(
      'ER326', 'Invalid Base Currency and Quote Currency combination.'),
  invalidPaymentMethodValue('ER327', 'Invalid payment method.'),
  internalError('ER328', 'Something went wrong.'),
  invalidExpireTimeValue('ER329', 'Invalid expire time.'),
  fixedAmountCurrencyError('ER330',
      'Exactly one of baseCurrencyAmount or quoteCurrencyAmount must be set when Fixed Amount is set.'),
  secretNotSet('ER331', 'Secret not set'),
  nullPaymentMethod('ER332', 'Payment Method should not be null.'),
  loginTokenNotFound('ER333', 'Login token not found.'),
  loginTokenExpired('ER334', 'Login token has expired.'),
  loginTokenNoUser('ER335', 'Login token has no user attached.'),
  invalidSignature('ER336', 'Signature is invalid.'),
  blankBaseCurrencyGeneral('ER337', 'Base Currency should not be blank.'),
  invalidSignatureType('ER338', 'Signature should be a string.'),
  missingRequiredSignature('ER339',
      'Signature is required when Wallet Address, Fee, Return Url or Callback Url is set.'),

  // Authentication errors (800-806)
  authenticationFailed('ER804', 'Authentication failed. Please try again.'),
  invalidAuthToken('ER800', 'Authorization token is invalid.'),
  expiredAuthToken('ER801', 'Authorization token has expired.'),
  missingAuthToken('ER802', 'Authorization token not found.'),
  multipleAuthMethods('ER803', 'Multiple authorization methods used.'),
  invalidApiKey('ER805', 'API key is invalid.'),
  missingApiKey('ER806', 'API key not found.'),

  // Network errors (900-904)
  networkError('ER900',
      'Network connection error. Please check your internet connection.'),
  timeoutError('ER901', 'Request timed out. Please try again.'),
  serverError('ER902', 'Server error. Please try again later.'),

  // General error
  unknown('ER999',
      'A general error has occurred. Please contact our support team.');

  final String code;
  final String defaultMessage;

  const BTCDirectErrorCode(this.code, this.defaultMessage);

  static BTCDirectErrorCode fromCode(String code) {
    return BTCDirectErrorCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => BTCDirectErrorCode.unknown,
    );
  }
}

extension BTCDirectErrorExt on Map<String, dynamic> {
  BTCDirectException toBTCDirectException() {
    final errors = this['errors'] as Map<String, dynamic>?;
    if (errors == null || errors.isEmpty) {
      return BTCDirectException(BTCDirectErrorCode.unknown);
    }

    final firstError = errors.entries.first;
    final errorData = firstError.value as Map<String, dynamic>;
    final code = BTCDirectErrorCode.fromCode(errorData['code'] as String);
    final message = errorData['message'] as String?;

    return BTCDirectException(code, customMessage: message);
  }
}
