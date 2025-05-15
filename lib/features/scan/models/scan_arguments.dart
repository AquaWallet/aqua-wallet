import 'package:aqua/features/qr_scan/models/qr_scan_arguments.dart';
import 'package:aqua/features/text_scan/models/text_scan_arguments.dart';

enum ScannerType { qr, text }

class ScanArguments {
  final QrScannerArguments qrArguments;
  final TextScannerArguments textArguments;
  final ScannerType initialType;

  ScanArguments({
    required this.qrArguments,
    required this.textArguments,
    this.initialType = ScannerType.qr,
  });
}
