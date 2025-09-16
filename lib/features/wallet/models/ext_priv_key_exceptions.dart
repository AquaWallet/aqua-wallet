import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:flutter/material.dart';

class MiniPrivateKeyException implements ExceptionLocalized {
  final MiniPrivateKeyExceptionType type;
  final String? customMessage;

  MiniPrivateKeyException(this.type, {this.customMessage});

  @override
  String toLocalizedString(BuildContext context) {
    switch (type) {
      case MiniPrivateKeyExceptionType.invalidMiniKey:
        return context.loc.invalidMiniPrivateKeyError;
      case MiniPrivateKeyExceptionType.generic:
        return customMessage ?? toString();
      default:
        throw ('Unhandled mini private key error');
    }
  }
}

enum MiniPrivateKeyExceptionType {
  invalidMiniKey,
  generic,
}
