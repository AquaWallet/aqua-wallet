import 'package:aqua/features/settings/settings.dart';

/// Whether to parse the QR code or just return the raw value
enum QrScannerParseAction {
  returnRawValue,
  attemptToParse,
}

class QrScannerArguments {
  final Asset? asset;
  final QrScannerParseAction parseAction;

  QrScannerArguments({
    this.asset,
    this.parseAction = QrScannerParseAction.returnRawValue,
  });
}
