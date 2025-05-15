import 'package:aqua/features/settings/settings.dart';

// TODO: This should be removed and QR scanner should always just pop back to caller. Caller should handle the navigation based on result.

enum QrOnSuccessNavAction { push, popBack }

/// Whether to parse the QR code or just return the raw value
enum QrScannerParseAction {
  returnRawValue,
  attemptToParse,
}

class QrScannerArguments {
  final Asset? asset;
  final QrScannerParseAction parseAction;
  final QrOnSuccessNavAction onSuccessAction;

  QrScannerArguments({
    this.asset,
    this.parseAction = QrScannerParseAction.returnRawValue,
    this.onSuccessAction = QrOnSuccessNavAction.push,
  });
}
