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
    'Bootleggers': RegExp(r'((.*)(wigroup\.co|yoyogroup\.co)(.*))'),
    'Zapper': RegExp(
        r'^((.*zapper\.com.*)|(.{2}\/.{4}\/.{20})|(.*payat\.io.*)|(.*(paynow\.netcash|paynow\.sagepay)\.co\.za.*)|(SK-\d{1,}-\d{23})|(\d{20})|(.*\d+\.zap\.pe(.*\n?)*)|(.*transactionjunction\.co\.za.*)|(CRSTPC-\d+-\d+-\d+-\d+-\d+))\s*$'),
    'ScanToPay': RegExp(r'(^\d{10}$)|(scantopay\.io)|(payat\.io)|(UMPQR)|(\.oltio\.co\.za)|(easypay)'),
    'SnapScan': RegExp(r'.*(snapscan).*'),
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
