import 'package:flutter/widgets.dart';
import 'package:ui_components/gen/ui_localizations.dart';

extension LocalizedBuildContext on BuildContext {
  UiLocalizations get loc => UiLocalizations.of(this)!;
}
