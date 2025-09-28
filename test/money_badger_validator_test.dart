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
      const qrData = 'https://za.wigroup.co/bill/415267598';

      final lightningAddress = MoneyBadgerValidator.convertToLightningAddress(
          qrData,
          isTestnet: true);
      expect(lightningAddress, contains('@staging.cryptoqr.net'));
      expect(lightningAddress,
          contains('https%3A%2F%2Fza.wigroup.co%2Fbill%2F415267598'));
    });

    test('properly encodes special characters', () {
      const qrData =
          '00020129530023za.co.electrum.picknpay0122TZHN7RSZPFAR3K/confirm+520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8';

      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(lightningAddress, contains('%2F')); // encoded '/'
      expect(lightningAddress, contains('%2B')); // encoded '+'
    });
    test('Zapper QR code with zap.pe domain', () {
      const qrData =
          "http://pay.zapper.com?t=6&i=40895:49955:7[34|0.00|3:10[39|ZAR,38|DillonDev";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "http%3A%2F%2Fpay.zapper.com%3Ft%3D6%26i%3D40895%3A49955%3A7%5B34%7C0.00%7C3%3A10%5B39%7CZAR%2C38%7CDillonDev@cryptoqr.net",
      );
    });

    test('Zapper QR code with zapper domain', () {
      const qrData =
          "http://2.zap.pe?t=6&i=40895:49955:7[34|0.00|3:10[39|ZAR,38|DillonDev";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "http%3A%2F%2F2.zap.pe%3Ft%3D6%26i%3D40895%3A49955%3A7%5B34%7C0.00%7C3%3A10%5B39%7CZAR%2C38%7CDillonDev@cryptoqr.net",
      );
    });

    test('Pay@ Bill Payment QR codes', () {
      const qrData = "ab/abcd/abcdefghijklmnopqrst";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "ab%2Fabcd%2Fabcdefghijklmnopqrst@cryptoqr.net",
      );
    });

    test('Matches payat.io URL', () {
      const qrData = "https://portal.payat.io/transactions/view?id=12345";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "https%3A%2F%2Fportal.payat.io%2Ftransactions%2Fview%3Fid%3D12345@cryptoqr.net",
      );
    });

    test('Matches paynow.netcash.co.za URL', () {
      const qrData = "https://paynow.netcash.co.za/qr/ABCDEF123456";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "https%3A%2F%2Fpaynow.netcash.co.za%2Fqr%2FABCDEF123456@cryptoqr.net",
      );
    });

    test('Matches paynow.sagepay.co.za URL', () {
      const qrData = "https://paynow.sagepay.co.za/pay/XYZ789";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "https%3A%2F%2Fpaynow.sagepay.co.za%2Fpay%2FXYZ789@cryptoqr.net",
      );
    });

    test('Standard Bank’s Scan to Pay / SnapScan–style reference', () {
      const qrData = "SK-123-12345678901234567890123";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "SK-123-12345678901234567890123@cryptoqr.net",
      );
    });

    test('Matches transactionjunction.co.za URL', () {
      const qrData = "https://www.transactionjunction.co.za/receipt/12345";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "https%3A%2F%2Fwww.transactionjunction.co.za%2Freceipt%2F12345@cryptoqr.net",
      );
    });

    test('Certain parking ticket formats (Servest Parking)', () {
      const qrData = "CRSTPC-12-345-6789-10-11";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "CRSTPC-12-345-6789-10-11@cryptoqr.net",
      );
    });

    test('ScanToPay QR code', () {
      const qrData = "https://qa.scantopay.io/pluto/public/qr/8784599487";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "https%3A%2F%2Fqa.scantopay.io%2Fpluto%2Fpublic%2Fqr%2F8784599487@cryptoqr.net",
      );
    });

    test('Snapscan QR code', () {
      const qrData = "https://pos.snapscan.io/qr/STB2ACC8";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "https%3A%2F%2Fpos.snapscan.io%2Fqr%2FSTB2ACC8@cryptoqr.net",
      );
    });

    test(
        'Bankserv / Payments Association of SA–aligned bill-payment references',
        () {
      const qrData = "12345678901234567890";
      final lightningAddress =
          MoneyBadgerValidator.convertToLightningAddress(qrData);
      expect(
        lightningAddress,
        "12345678901234567890@cryptoqr.net",
      );
    });
  });
}
