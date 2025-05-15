import 'package:aqua/features/settings/settings.dart';

enum TextOnSuccessNavAction { push, popBack }

enum TextScannerParseAction {
  returnRawValue,
  attemptToParse,
}

class TextScannerArguments {
  final Asset? asset;
  final TextScannerParseAction parseAction;
  final TextOnSuccessNavAction onSuccessAction;

  TextScannerArguments({
    this.asset,
    this.parseAction = TextScannerParseAction.returnRawValue,
    this.onSuccessAction = TextOnSuccessNavAction.push,
  });
}
