import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:coin_cz/features/lightning/lightning.dart';
import 'package:coin_cz/features/qr_scan/qr_scan.dart';
import 'package:coin_cz/features/sam_rock/pages/sam_rock_screen.dart';
import 'package:coin_cz/features/send/send.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerScreen extends HookConsumerWidget {
  static const routeName = '/qrScannerScreen';
  final QrScannerArguments arguments;

  const QrScannerScreen({super.key, required this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrKey = useMemoized(GlobalKey.new);
    final scannerInit = ref.watch(qrScannerInitializationProvider(arguments));

    final showExceptionDialog = useCallback((String alertSubtitle) {
      showDialog<CustomAlertDialog>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CustomAlertDialog(
          title: context.loc.scanQrCodeValidationAlertTitle,
          subtitle: alertSubtitle,
          controlWidgets: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  dialogContext.pop();
                  ref.read(qrScanProvider.notifier).restartCamera();
                },
                child: Text(context.loc.tryAgain),
              ),
            ),
          ],
        ),
      );
    });

    final onClipboardPasted = useCallback(() async {
      final data = await Clipboard.getData(Clipboard.kTextPlain);

      if (data?.text != null && context.mounted) {
        await ref
            .read(qrCodeStateProvider(arguments).notifier)
            .processBarcode(data!.text);
      }
    });

    ref.listen(qrScanProvider, (_, data) async {
      if (data.hasError) {
        final error = data.error;
        final errorMessage = error is ExceptionLocalized
            ? error.toLocalizedString(context)
            : QrScannerInvalidQrParametersException()
                .toLocalizedString(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showExceptionDialog(errorMessage);
        });
      }
    });

    //TODO: Big issue here. Scanner screen does the pushing.
    // 1. We need to move the logic of pushing to the caller.
    ref.listen(qrCodeStateProvider(arguments), (prev, next) {
      if (prev is AsyncData && next is AsyncData && prev?.value == next.value) {
        return;
      }

      next.when(
        data: (data) => data.maybeWhen(
          unknownQrCode: (code) => context.pop(code),
          pullSendAsset: (args) => context.pop(args),
          pushSendAsset: (args) async {
            await context.push(SendAssetScreen.routeName, extra: args);
            ref.read(qrScanProvider.notifier).restartCamera();
          },
          lnurlWithdraw: (args) => context.push(
            LnurlWithdrawScreen.routeName,
            extra: args,
          ),
          samRock: (args) => context.push(
            SamRockScreen.routeName,
            extra: args,
          ),
          orElse: () => null,
        ),
        error: (error, stack) {
          if (context.mounted) {
            final exceptionLocalized = error is ExceptionLocalized
                ? error.toLocalizedString(context)
                : QrScannerInvalidQrParametersException()
                    .toLocalizedString(context);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showExceptionDialog(exceptionLocalized);
            });
          }
        },
        loading: () => null,
      );
    });

    ref.listen(
      qrScannerShowPermissionAlertProvider(arguments),
      (_, __) {
        showDialog<CustomAlertDialog>(
          context: context,
          barrierDismissible: false,
          builder: (context) => CustomAlertDialog(
            title: context.loc.scanQrCodePermissionAlertTitle,
            subtitle: context.loc.scanQrCodePermissionAlertSubtitle,
            controlWidgets: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.pop(context),
                  child: Text(
                    context.loc.cancel,
                  ),
                ),
              ),
              Container(width: 12.0),
              Expanded(
                child: ElevatedButton(
                  onPressed: ref
                      .read(qrScannerProvider(arguments))
                      .popWithRequiresRestartResult,
                  child: Text(context.loc.scanQrCodePermissionAlertGrantButton),
                ),
              ),
            ],
          ),
        );
      },
    );

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: SafeArea(
        top: false,
        bottom: false,
        child: scannerInit.maybeWhen(
          data: (_) => Stack(
            children: [
              //ANCHOR - Scanner view
              Container(
                margin: const EdgeInsets.only(top: 28.0),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30.0),
                    topRight: Radius.circular(30.0),
                  ),
                  child: MobileScanner(
                    key: qrKey,
                    controller: ref.read(qrScanProvider.notifier).controller,
                    onDetect: (_) {},
                  ),
                ),
              ),
              //ANCHOR - Scanner overlay
              Center(
                child: SizedBox.square(
                  dimension: 196.0,
                  child: CustomPaint(
                    painter: ScannerOverlayPainter(
                      borderRadius: 25.0,
                      borderColor: context.colorScheme.secondaryContainer,
                    ),
                  ),
                ),
              ),
              Column(
                children: [
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 36.0),
                    margin: const EdgeInsets.only(bottom: 78.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        //ANCHOR - Paste button
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.all(Radius.circular(10.0)),
                          ),
                          child: IconButton(
                            color: Colors.black,
                            icon: const Icon(Icons.paste_outlined),
                            onPressed: onClipboardPasted,
                          ),
                        ),
                        Row(
                          children: [
                            //ANCHOR - Pick image button
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                              ),
                              child: IconButton(
                                color: Colors.black,
                                icon: const Icon(Icons.photo_library_outlined),
                                onPressed: ref
                                    .read(qrScanProvider.notifier)
                                    .scanImageForBarcode,
                              ),
                            ),
                            const SizedBox(width: 20.0),
                            //ANCHOR - Flash button
                            Container(
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(10.0)),
                              ),
                              child: IconButton(
                                color: Colors.black,
                                icon: const Icon(Icons.flashlight_on_outlined),
                                onPressed: ref
                                    .read(qrScanProvider.notifier)
                                    .toggleFlash,
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
                context.colorScheme.secondaryContainer,
              ),
            ),
          ),
          orElse: () => const SizedBox.shrink(),
        ),
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
      ..strokeWidth = 2.0
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
