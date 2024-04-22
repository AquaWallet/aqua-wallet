import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart' show rootBundle;

// Represents the list of words used to provide suggestions for the mnemonic

final walletHintWordListProvider = FutureProvider<List<String>>((_) async {
  try {
    final words = await rootBundle.loadString('assets/wordlist.txt');
    return words.split('\n');
  } catch (e) {
    throw WalletRestoreInvalidOptionsException();
  }
});

final walletInputHintsProvider =
    Provider.autoDispose.family<WalletInputHintsNotifier, int>((ref, index) {
  final options = ref.watch(walletHintWordListProvider).asData?.value ?? [];
  final text = ref.watch(mnemonicWordInputStateProvider(index)).text;
  return WalletInputHintsNotifier(options, text);
});

class WalletInputHintsNotifier {
  WalletInputHintsNotifier(this._options, this._text);

  final List<String> _options;
  final String _text;

  List<String> get options {
    if (_text.isEmpty) {
      return [];
    }
    return _options.where((String option) {
      return option.startsWith(_text.toLowerCase());
    }).toList();
  }
}
