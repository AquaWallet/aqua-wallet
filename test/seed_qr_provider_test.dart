import 'package:aqua/features/onboarding/restore/providers/mnemonic_word_input_state_provider.dart';
import 'package:aqua/features/onboarding/restore/providers/wallet_restore_suggestions_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua/features/recovery/providers/seed_qr_provider.dart';

final testCases = [
  {
    'seedList':
        'attack pizza motion avocado network gather crop fresh patrol unusual wild holiday candy pony ranch winter theme error hybrid van cereal salon goddess expire'
            .split(' '),
    'expectedQRCode':
        '011513251154012711900771041507421289190620080870026613431420201617920614089619290300152408010643'
  },
  {
    'seedList':
        'atom solve joy ugly ankle message setup typical bean era cactus various odor refuse element afraid meadow quick medal plate wisdom swap noble shallow'
            .split(' '),
    'expectedQRCode':
        '011416550964188800731119157218870156061002561932122514430573003611011405110613292018175411971576'
  },
  {
    'seedList':
        'sound federal bonus bleak light raise false engage round stock update render quote truck quality fringe palace foot recipe labor glow tortoise potato still'
            .split(' '),
    'expectedQRCode':
        '166206750203018810361417065805941507171219081456140818651401074412730727143709940798183613501710'
  },
  {
    'seedList':
        'forum undo fragile fade shy sign arrest garment culture tube off merit'
            .split(' '),
    'expectedQRCode': '073318950739065415961602009907670428187212261116'
  },
  {
    'seedList':
        'good battle boil exact add seed angle hurry success glad carbon whisper'
            .split(' '),
    'expectedQRCode': '080301540200062600251559007008931730078802752004'
  },
  {
    'seedList':
        'approve fruit lens brass ring actual stool coin doll boss strong rate'
            .split(' '),
    'expectedQRCode': '008607501025021714880023171503630517020917211425'
  }
]; // from https://github.com/SeedSigner/seedsigner/blob/dev/docs/seed_qr/README.md#test-seedqrs

void main() {
  final container = ProviderContainer();
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Seed QR Provider', () {
    setUp(() async {
      await container.read(walletHintWordListProvider.future);
    });

    test('generateQRCodeFromSeedList', () async {
      for (final testCase in testCases) {
        final result = container
            .read(seedQrProvider.notifier)
            .generateQRCodeFromSeedList(testCase['seedList'] as List<String>);
        expect(result, testCase['expectedQRCode']);
      }
    });

    test('generateQRCodeFromSeedList with null input', () async {
      final result = container
          .read(seedQrProvider.notifier)
          .generateQRCodeFromSeedList(null);
      expect(result, '');
    });

    test('extractSeedListFromQRCode', () async {
      for (final testCase in testCases) {
        final qrCode = testCase['expectedQRCode'] as String;
        final expectedSeedList = testCase['seedList'] as List<String>;

        final result = container
            .read(seedQrProvider.notifier)
            .extractSeedListFromQRCode(qrCode);
        expect(result, expectedSeedList);
      }
    });

    test('extractSeedListFromQRCode with invalid input', () async {
      const invalidQRCode = 'invalid_qr_code';
      final result = container
          .read(seedQrProvider.notifier)
          .extractSeedListFromQRCode(invalidQRCode);
      expect(result, []);
    });

    test('extractSeedListFromQRCode with empty input', () async {
      final result =
          container.read(seedQrProvider.notifier).extractSeedListFromQRCode('');
      expect(result, []);
    });

    test('populateFromQrCode', () async {
      final testCase = testCases[3]; // test case with 12 words
      container
          .read(seedQrProvider.notifier)
          .populateFromQrCode(testCase['expectedQRCode'] as String);

      (testCase['seedList'] as List<String>).forEachIndexed((index, word) {
        final wordInputState =
            container.read(mnemonicWordInputStateProvider(index));
        expect(wordInputState.text, word);
      });
    });
  });
}
