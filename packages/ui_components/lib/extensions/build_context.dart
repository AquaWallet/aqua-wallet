import 'package:flutter/widgets.dart';
import 'package:ui_components/gen/ui_localizations.dart';

extension BuildContextX on BuildContext {
  UiLocalizations get loc => UiLocalizations.of(this)!;
}
