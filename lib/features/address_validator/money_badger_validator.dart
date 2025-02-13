/// MoneyBadger Lightning Address validator and parser
/// Handles retail QR codes that can be converted to Lightning addresses
///
/// To test with sample QR codes:
///
/// 1. Staging Environment:
///    ```bash
///    curl -s -o /dev/null -D - 'https://staging.circuit.cryptoconvert.co.za/test/qr.png?amountCents=100&completion=confirm'
///    ```
///    Look for x-mpm-code header in response
///
/// 2. Production Environment:
///    ```bash
///    curl -s -o /dev/null -D - 'https://api.circuit.cryptoconvert.co.za/test/qr.png?amountCents=100&completion=confirm'
///    ```
///
/// Example QR data:
/// ```
/// 00020129530023za.co.electrum.picknpay0122TZHN7RSZPFAR3K/confirm520458125303710540115802ZA5916cryptoqrtestscan6002CT63049FB8
/// ```
///
/// Important: QR data must be URL-encoded before use, particularly:
/// - "/" becomes "%2f"
/// - "+" becomes "%2b"
///
/// Note: Test QR codes can only be used once. This restriction doesn't apply to actual retailer QR codes.
class MoneyBadgerValidator {
  static const String _stagingDomain = 'staging.cryptoqr.net';
  static const String _productionDomain = 'cryptoqr.net';

  static final _retailerRegexes = {
    'PnP': RegExp(r'(.*)(za\.co\.electrum\.picknpay)(.*)'),
    'Ecentric': RegExp(r'(.*)(za\.co\.ecentric)(.*)'),
  };

  /// Validates if a QR code is from a supported MoneyBadger retailer
  static bool isValidRetailerQR(String qrData) {
    return _retailerRegexes.values.any((regex) => regex.hasMatch(qrData));
  }

  /// Converts a retail QR code to a Lightning address
  /// Returns null if the QR code is not from a supported retailer
  static String? convertToLightningAddress(String qrData,
      {bool isTestnet = false}) {
    if (!isValidRetailerQR(qrData)) {
      return null;
    }

    // URL encode the QR data, particularly handling '/' and '+'
    final encodedQrData = Uri.encodeComponent(qrData);

    // Choose domain based on network
    final domain = isTestnet ? _stagingDomain : _productionDomain;

    return '$encodedQrData@$domain';
  }
}
