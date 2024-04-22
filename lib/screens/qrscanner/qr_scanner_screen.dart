import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum QrOnSuccessAction { push, pull }

class QrScannerScreenArguments {
  Asset? asset;

  /// Throw an error if the scanned QR is a different asset than the one passed in
  bool throwErrorOnAssetMismatch;

  /// Try to parse the address per asset
  /// If `false`, will return QR text to `onSuccessAction` as is
  bool parseAddress;
  QrOnSuccessAction onSuccessAction;

  QrScannerScreenArguments(
      {this.asset,
      this.throwErrorOnAssetMismatch = false,
      this.parseAddress = false,
      this.onSuccessAction = QrOnSuccessAction.push});
}

class QrScannerScreen extends ConsumerStatefulWidget {
  static const routeName = '/qrScannerScreen';

  const QrScannerScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState extends ConsumerState<QrScannerScreen> {
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  final _imagePicker = ImagePicker();
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  handleAddress(QrScannerScreenArguments arguments, String? address) async {
    await cameraController.stop();
    logger.d(
        '[QR] handleAddress - address: $address - parseAddress: ${arguments.parseAddress} - onSuccessAction: ${arguments.onSuccessAction}');

    try {
      // If we don't need to parse the address, just return the QR text
      if (arguments.parseAddress == false) {
        if (address == null || arguments.asset == null) {
          throw QrScannerInvalidQrParametersException();
        }
        var args = SendAssetArguments.fromAsset(arguments.asset!)
            .copyWith(input: address);
        if (context.mounted) {
          if (arguments.onSuccessAction == QrOnSuccessAction.pull) {
            return Navigator.of(context).pop(args);
          } else {
            ref.read(sendNavigationEntryProvider(args)).call(context);
          }
        }
      }
      // Else, parse the address per asset
      else {
        final result = await ref
            .read(qrScannerProvider(arguments))
            .parseQrAddressScan(address, asset: arguments.asset);

        result?.maybeWhen(
            parsedAddress: (parsedAddress) {
              // If we are expecting a specific asset, throw an error if the scanned QR is a not compatible asset
              if (arguments.asset != null &&
                  parsedAddress.asset != null &&
                  arguments.asset!.isCompatibleWith(parsedAddress.asset!) ==
                      false &&
                  arguments.throwErrorOnAssetMismatch) {
                throw QrScannerIncompatibleAssetIdException();
              }

              // Return results
              var args = SendAssetArguments.fromAsset(parsedAddress.asset!)
                  .copyWith(
                      input: parsedAddress.address,
                      userEnteredAmount: parsedAddress.amount,
                      lnurlParseResult: parsedAddress.lnurlParseResult);
              logger.d('[QR] handleAddress - success - passing args: $args');

              if (arguments.onSuccessAction == QrOnSuccessAction.pull) {
                return Navigator.of(context).pop(args);
              } else {
                ref.read(sendNavigationEntryProvider(args)).call(context);
              }
            },
            orElse: () => null);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      if (!context.mounted) {
        return;
      }

      final exceptionLocalized = e is ExceptionLocalized
          ? e.toLocalizedString(context)
          : QrScannerInvalidQrParametersException().toLocalizedString(context);
      _showExceptionDialog(context, exceptionLocalized);
    }
  }

  @override
  void initState() {
    cameraController.start();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    if (cameraController.isStarting) {
      cameraController.stop();
    }
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as QrScannerScreenArguments;

    ref.listen(
      qrScannerShowPermissionAlertProvider(arguments),
      (_, __) {
        _showPermissionErrorDialog(context);
      },
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaAppBar(
        title: context.loc.scanQrCodeTitle,
        showActionButton: false,
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Consumer(builder: (_, watch, __) {
          final value = ref.watch(qrScannerInitializationProvider(arguments));
          return value.maybeWhen(
            data: (_) => Stack(
              children: [
                Container(
                  margin: EdgeInsets.only(top: 28.h),
                  child: ClipRRect(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.r),
                      topRight: Radius.circular(30.r),
                    ),
                    child: MobileScanner(
                      key: _qrKey,
                      controller: cameraController,
                      onDetect: (barcode) async {
                        await handleAddress(
                            arguments, barcode.barcodes.first.rawValue);
                      },
                    ),
                  ),
                ),
                Center(
                  child: SizedBox.square(
                    dimension: 196.r,
                    child: CustomPaint(
                      painter: ScannerOverlayPainter(
                        borderColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: 25.r,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Expanded(
                      child: Text(''),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 36.w),
                      margin: EdgeInsets.only(bottom: 78.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10.r)),
                            ),
                            child: IconButton(
                              color: Colors.black,
                              icon: const Icon(Icons.paste_outlined),
                              onPressed: () async {
                                ClipboardData? data = await Clipboard.getData(
                                    Clipboard.kTextPlain);

                                if (data?.text != null) {
                                  await handleAddress(arguments, data!.text);
                                }
                              },
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.r)),
                                ),
                                child: IconButton(
                                  color: Colors.black,
                                  icon:
                                      const Icon(Icons.photo_library_outlined),
                                  onPressed: () async {
                                    //NOTE: Setting `maxWidth` and `maxHeight` to `double.infinity` is a workaround for a bug on mobile_scanner on iOS when trying to analyze an image from image_picker that comes from the same device.
                                    //SEE: https: //github.com/juliansteenbakker/mobile_scanner/issues/164
                                    final image = await _imagePicker.pickImage(
                                      source: ImageSource.gallery,
                                      maxWidth: double.infinity,
                                      maxHeight: double.infinity,
                                    );
                                    final path = image?.path;
                                    if (path != null) {
                                      final result = await cameraController
                                          .analyzeImage(path);
                                      if (!result) {
                                        if (context.mounted) {
                                          final exceptionString =
                                              QrScannerInvalidQrParametersException()
                                                  .toLocalizedString(context);
                                          _showExceptionDialog(
                                              context, exceptionString);
                                        }
                                      }
                                    }
                                  },
                                ),
                              ),
                              SizedBox(
                                width: 20.w,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10.r)),
                                ),
                                child: IconButton(
                                  color: Colors.black,
                                  icon:
                                      const Icon(Icons.flashlight_on_outlined),
                                  onPressed: () =>
                                      cameraController.toggleTorch(),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            loading: () => Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  Theme.of(context).colorScheme.secondaryContainer,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          );
        }),
      ),
    );
  }

  void _showExceptionDialog(BuildContext context, String alertSubtitle) {
    showDialog<CustomAlertDialog>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomAlertDialog(
        onWillPop: () async => false,
        title: context.loc.scanQrCodeValidationAlertTitle,
        subtitle: alertSubtitle,
        controlWidgets: [
          Expanded(
            child: ElevatedButton(
              child: Text(context.loc.scanQrCodeValidationAlertRetryButton),
              onPressed: () {
                Navigator.pop(context);
                cameraController.start();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showPermissionErrorDialog(BuildContext context) {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    showDialog<CustomAlertDialog>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CustomAlertDialog(
          onWillPop: () async {
            return false;
          },
          title: context.loc.scanQrCodePermissionAlertTitle,
          subtitle: context.loc.scanQrCodePermissionAlertSubtitle,
          controlWidgets: [
            Expanded(
              child: OutlinedButton(
                child: Text(context.loc.scanQrCodePermissionAlertCancelButton),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Container(width: 12.w),
            Expanded(
              child: ElevatedButton(
                child: Text(context.loc.scanQrCodePermissionAlertGrantButton),
                onPressed: () async {
                  ref
                      .read(qrScannerProvider(arguments))
                      .popWithRequiresRestartResult();
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;

  ScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sh = size.height;
    final sw = size.width;
    final cornerSide = borderRadius;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 2.r
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(cornerSide, 0)
      ..quadraticBezierTo(0, 0, 0, cornerSide)
      ..moveTo(0, sh - cornerSide)
      ..quadraticBezierTo(0, sh, cornerSide, sh)
      ..moveTo(sw - cornerSide, sh)
      ..quadraticBezierTo(sw, sh, sw, sh - cornerSide)
      ..moveTo(sw, cornerSide)
      ..quadraticBezierTo(sw, 0, sw - cornerSide, 0);

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawShadow(path, shadowPaint.color, 10, false);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
