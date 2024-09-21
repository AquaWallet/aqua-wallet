import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

enum QrOnSuccessAction { push, pull }

enum QrScannerParseAction {
  doNotParse,
  parse,
}

class QrScannerScreenArguments {
  Asset? asset;
  QrScannerParseAction parseAction;
  QrOnSuccessAction onSuccessAction;

  QrScannerScreenArguments(
      {this.asset,
      this.parseAction = QrScannerParseAction.doNotParse,
      this.onSuccessAction = QrOnSuccessAction.push});
}

class QrScannerScreen extends HookConsumerWidget {
  static const routeName = '/qrScannerScreen';

  const QrScannerScreen({super.key});

  handleAddress(
      QrScannerScreenArguments arguments,
      String? input,
      MobileScannerController cameraController,
      BuildContext context,
      WidgetRef ref) async {
    await cameraController.stop();
    logger.d(
        '[QR] handleAddress - address: $input - parseAddress: ${arguments.parseAction} - onSuccessAction: ${arguments.onSuccessAction}');

    try {
      if (arguments.parseAction == QrScannerParseAction.doNotParse) {
        if (input == null) {
          throw QrScannerInvalidQrParametersException();
        }

        if (arguments.asset == null) {
          if (context.mounted) {
            if (arguments.onSuccessAction == QrOnSuccessAction.pull) {
              return Navigator.of(context).pop(input);
            } else {
              throw QrScannerInvalidQrParametersException();
            }
          }
        }

        final args = SendAssetArguments.fromAsset(arguments.asset!)
            .copyWith(input: input);

        if (context.mounted) {
          if (arguments.onSuccessAction == QrOnSuccessAction.pull) {
            return Navigator.of(context).pop(args);
          } else {
            ref.read(sendNavigationEntryProvider(args)).call(context);
          }
        }
      } else {
        final result = await ref
            .read(qrScannerProvider(arguments))
            .parseQrAddressScan(input, asset: arguments.asset);

        result?.maybeWhen(
            lnurlWithdraw: (lnurlParseResult) {
              Navigator.of(context).pushNamed(
                LnurlWithdrawScreen.routeName,
                arguments: lnurlParseResult.withdrawalParams,
              );
            },
            send: (parsedAddress) {
              // If we are expecting a specific asset, throw an error if the scanned QR is a not compatible asset
              if (arguments.asset != null &&
                  parsedAddress.asset != null &&
                  arguments.asset!.isCompatibleWith(parsedAddress.asset!) ==
                      false) {
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
      if (!context.mounted) {
        return;
      }

      final exceptionLocalized = e is ExceptionLocalized
          ? e.toLocalizedString(context)
          : QrScannerInvalidQrParametersException().toLocalizedString(context);
      _showExceptionDialog(context, exceptionLocalized, cameraController);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final MobileScannerController cameraController =
        useMemoized(() => MobileScannerController(
              detectionSpeed: DetectionSpeed.normal,
              facing: CameraFacing.back,
              torchEnabled: false,
            ));

    final ImagePicker imagePicker = useMemoized(() => ImagePicker());

    useEffect(() {
      cameraController.start();

      return () {
        if (cameraController.isStarting) {
          cameraController.stop();
        }
        cameraController.dispose();
      };
    }, []);

    final arguments =
        ModalRoute.of(context)?.settings.arguments as QrScannerScreenArguments;

    ref.listen(
      qrScannerShowPermissionAlertProvider(arguments),
      (_, __) {
        final arguments = ModalRoute.of(context)?.settings.arguments;
        showDialog<CustomAlertDialog>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return CustomAlertDialog(
              title: context.loc.scanQrCodePermissionAlertTitle,
              subtitle: context.loc.scanQrCodePermissionAlertSubtitle,
              controlWidgets: [
                Expanded(
                  child: OutlinedButton(
                    child:
                        Text(context.loc.scanQrCodePermissionAlertCancelButton),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
                Container(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    child:
                        Text(context.loc.scanQrCodePermissionAlertGrantButton),
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
                      controller: cameraController,
                      onDetect: (barcode) async {
                        await handleAddress(
                            arguments,
                            barcode.barcodes.first.rawValue,
                            cameraController,
                            context,
                            ref);
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

                                if (data?.text != null && context.mounted) {
                                  await handleAddress(arguments, data!.text,
                                      cameraController, context, ref);
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
                                    final image = await imagePicker.pickImage(
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
                                              context,
                                              exceptionString,
                                              cameraController);
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

  void _showExceptionDialog(BuildContext context, String alertSubtitle,
      MobileScannerController cameraController) {
    showDialog<CustomAlertDialog>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomAlertDialog(
        title: context.loc.scanQrCodeValidationAlertTitle,
        subtitle: alertSubtitle,
        controlWidgets: [
          Expanded(
            child: ElevatedButton(
              child: Text(context.loc.tryAgain),
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
