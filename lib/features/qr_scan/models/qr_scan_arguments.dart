import 'package:aqua/features/settings/settings.dart';

enum QrOnSuccessAction { push, pull }

enum QrScannerParseAction {
  doNotParse,
  parse,
}

class QrScannerArguments {
  final Asset? asset;
  final QrScannerParseAction parseAction;
  final QrOnSuccessAction onSuccessAction;

  QrScannerArguments({
    this.asset,
    this.parseAction = QrScannerParseAction.doNotParse,
    this.onSuccessAction = QrOnSuccessAction.push,
  });
}
