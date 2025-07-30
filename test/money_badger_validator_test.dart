import 'package:aqua/features/address_validator/money_badger_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyBadgerValidator', () {
    test('validates Pick n Pay QR code', () {
      const qrData =
          '00020129530023za.co.electrum.picknpay0122TZHN7RSZPFAR3K/confirm520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8';

      expect(MoneyBadgerValidator.isValidRetailerQR(qrData), true);
    });

    test('validates Ecentric QR code', () {
      const qrData =
          '00020129530019za.co.ecentric.payment0122RD2HAK3KTI53EC/confirm520458125303710540115802ZA5916cryptoqrtestscan6002CT63049BE2';

      expect(MoneyBadgerValidator.isValidRetailerQR(qrData), true);
    });

    test('rejects invalid QR code', () {
      const qrData =
          '00020129530023invalid.retailer0122TZHN7RSZPFAR3K/confirm520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8';

      expect(MoneyBadgerValidator.isValidRetailerQR(qrData), false);
    });

    test('converts Pick n Pay QR to Lightning address on mainnet', () {
      const qrData =
          '00020129530023za.co.electrum.picknpay0122TZHN7RSZPFAR3K/confirm520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8';

      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(lightningAddress, contains('@cryptoqr.net'));
      expect(lightningAddress, contains('za.co.electrum.picknpay'));
    });

    test('converts Pick n Pay QR to Lightning address on testnet', () {
      const qrData =
          '00020129530023za.co.electrum.picknpay0122TZHN7RSZPFAR3K/confirm520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8';

      final lightningAddress = MoneyBadgerValidator.convertToLightningAddress(
          qrData,
          isTestnet: true);
      expect(lightningAddress, contains('@staging.cryptoqr.net'));
      expect(lightningAddress, contains('za.co.electrum.picknpay'));
    });

    test('converts Bootlegger QR to Lightning address on testnet', () {
      const qrData ='https://za.wigroup.co/bill/415267598';

      final lightningAddress = MoneyBadgerValidator.convertToLightningAddress(
          qrData,
          isTestnet: true);
      expect(lightningAddress, contains('@staging.cryptoqr.net'));
      expect(lightningAddress, contains('https%3A%2F%2Fza.wigroup.co%2Fbill%2F415267598'));
    });

    test('properly encodes special characters', () {
      const qrData =
          '00020129530023za.co.electrum.picknpay0122TZHN7RSZPFAR3K/confirm+520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8';

      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(lightningAddress, contains('%2F')); // encoded '/'
      expect(lightningAddress, contains('%2B')); // encoded '+'
    });
  });
}
