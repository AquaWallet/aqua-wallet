import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:rxdart/rxdart.dart';

// Provider responsible for scanning QR codes from camera feed and image files

final _logger = CustomLogger(FeatureFlag.qr);

final qrScanProvider =
    AutoDisposeStreamNotifierProvider<QrScanNotifier, String?>(
        QrScanNotifier.new);

class QrScanNotifier extends AutoDisposeStreamNotifier<String?> {
  final controller = MobileScannerController();
  final _imagePicker = ImagePicker();

  @override
  Stream<String?> build() => controller.barcodes
      .mapNotNull((e) => e.barcodes.firstOrNull?.rawValue)
      .doOnEach((code) => _logger.debug('[QR][Scan] ScannedBarcode: $code'))
      .distinct();

  Future<void> scanImageForBarcode() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      final result = await controller.analyzeImage(file.path);
      _logger.debug('[QR][Scan] AnalyzedImage: $result');
    } else {
      throw QrScannerInvalidQrParametersException();
    }
  }

  void restartCamera() {
    ref.invalidateSelf();
  }

  void toggleFlash() {
    controller.toggleTorch();
  }
}
