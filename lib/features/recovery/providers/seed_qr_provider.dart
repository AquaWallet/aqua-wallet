import 'package:aqua/features/onboarding/restore/providers/mnemonic_word_input_state_provider.dart';
import 'package:aqua/features/onboarding/restore/providers/wallet_restore_suggestions_provider.dart';
import 'package:aqua/features/shared/shared.dart';

final seedQrProvider =
    AsyncNotifierProvider.autoDispose<_SeedQrUtils, void>(() {
  return _SeedQrUtils();
});

class _SeedQrUtils extends AutoDisposeAsyncNotifier {
  static const int _mnemonicIndexLength = 4;
  static final RegExp _regExpForNumbers = RegExp(r'^[0-9]+$');

  @override
  void build() {}

  List<String> get _wordList {
    return ref.read(walletHintWordListProvider).asData?.value ?? [];
  }

  String generateQRCodeFromSeedList(List<String>? seedList) {
    if (seedList == null || seedList.isEmpty) {
      return '';
    }

    String result = '';
    for (String word in seedList) {
      int index = _wordList.indexOf(word);
      if (index == -1) {
        return '';
      }
      result += index.toString().padLeft(_mnemonicIndexLength, '0');
    }
    return result;
  }

  List<String> extractSeedListFromQRCode(String code) {
    if (code.length % _mnemonicIndexLength == 0 &&
        _regExpForNumbers.hasMatch(code)) {
      List<String> result = [];
      for (int i = 0; i < code.length; i += _mnemonicIndexLength) {
        int index = int.parse(code.substring(i, i + _mnemonicIndexLength));
        result.add(_wordList[index]);
      }
      return result;
    }
    return [];
  }

  void populateFromQrCode(String qrCode) {
    final seedList = extractSeedListFromQRCode(qrCode);
    if (seedList.length == 12) {
      seedList.forEachIndexed((index, word) {
        ref
            .read(mnemonicWordInputStateProvider(index).notifier)
            .update(text: word);
      });
    }
  }
}
