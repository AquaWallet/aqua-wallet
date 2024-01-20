import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// observer used to notify the caller when the locale changes
class _LocaleObserver extends WidgetsBindingObserver {
  _LocaleObserver(this._didChangeLocales);
  final void Function(List<Locale>? locales) _didChangeLocales;
  @override
  void didChangeLocales(List<Locale>? locales) {
    _didChangeLocales(locales);
  }
}

/// provider used to access the AppLocalizations object for the current locale
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  // 1. initialize from the initial locale
  ref.state =
      lookupAppLocalizations(WidgetsBinding.instance.platformDispatcher.locale);
  // 2. create an observer to update the state
  final observer = _LocaleObserver((locales) {
    ref.state = lookupAppLocalizations(
        WidgetsBinding.instance.platformDispatcher.locale);
  });
  // 3. register the observer and dispose it when no longer needed
  final binding = WidgetsBinding.instance;
  binding.addObserver(observer);
  ref.onDispose(() => binding.removeObserver(observer));

  return ref.state;
});
