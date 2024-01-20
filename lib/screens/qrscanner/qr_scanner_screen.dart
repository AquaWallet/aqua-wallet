import 'package:aqua/data/models/exception_localized.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum QrOnSuccessAction { push, pull }

class QrScannerScreenArguments {
  String? network;
  Asset? asset;

  /// Try to parse the address per asset
  /// If `false`, will return QR text to `onSuccessAction` as is
  bool parseAddress;
  QrOnSuccessAction onSuccessAction;

  QrScannerScreenArguments(
      {this.network,
      this.asset,
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

  handleAddress(arguments, String? address,
      MobileScannerController cameraController) async {
    await cameraController.stop();

    try {
      // If we don't need to parse the address, just return the QR text
      if (arguments.parseAddress == false) {
        if (address == null || arguments.asset == null) {
          throw QrScannerInvalidQrParametersException();
        }
        var args = SendAssetArguments.fromAsset(arguments.asset!)
            .copyWith(address: address);
        if (context.mounted) {
          Navigator.of(context)
              .pushReplacementNamed(SendAssetScreen.routeName, arguments: args);
        }
      }
      // Else, parse the address per asset
      else {
        final result = await ref
            .read(qrScannerProvider(arguments))
            .validateQrAddressScan(address);

        result?.maybeWhen(
            success: (address, asset, amount, label, message) {
              double? parsedAmount;
              if (amount != null) {
                parsedAmount = double.parse(amount);
              }
              var args = SendAssetArguments.fromAsset(asset!)
                  .copyWith(address: address, userEnteredAmount: parsedAmount);

              if (arguments.onSuccessAction == QrOnSuccessAction.pull) {
                return Navigator.of(context).pop(args);
              }

              Navigator.of(context).pushReplacementNamed(
                  SendAssetScreen.routeName,
                  arguments: args);
            },
            orElse: () => null);
      }
    } catch (e) {
      if (context.mounted) {
        String alertSubtitle = e is ExceptionLocalized
            ? e.toLocalizedString(context)
            : QrScannerInvalidQrParametersException()
                .toLocalizedString(context);

        showDialog<CustomAlertDialog>(
          context: context,
          barrierDismissible: false,
          builder: (context) => CustomAlertDialog(
            onWillPop: () async => false,
            title: AppLocalizations.of(context)!.scanQrCodeValidationAlertTitle,
            subtitle: alertSubtitle,
            controlWidgets: [
              Expanded(
                child: ElevatedButton(
                  child: Text(AppLocalizations.of(context)!
                      .scanQrCodeValidationAlertRetryButton),
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
    }
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

    MobileScannerController cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
    return Scaffold(
      appBar: AquaAppBar(
        title: AppLocalizations.of(context)!.scanQrCodeTitle,
        showActionButton: false,
      ),
      body: SafeArea(
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
                        await handleAddress(arguments,
                            barcode.barcodes.first.rawValue, cameraController);
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
                                  await handleAddress(
                                      arguments, data!.text, cameraController);
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
                                    final image = await _imagePicker.pickImage(
                                        source: ImageSource.gallery);
                                    final path = image?.path;
                                    if (path != null) {
                                      await cameraController.analyzeImage(path);
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
          title: AppLocalizations.of(context)!.scanQrCodePermissionAlertTitle,
          subtitle:
              AppLocalizations.of(context)!.scanQrCodePermissionAlertSubtitle,
          controlWidgets: [
            Expanded(
              child: OutlinedButton(
                child: Text(AppLocalizations.of(context)!
                    .scanQrCodePermissionAlertCancelButton),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Container(width: 12.w),
            Expanded(
              child: ElevatedButton(
                child: Text(AppLocalizations.of(context)!
                    .scanQrCodePermissionAlertGrantButton),
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

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
