import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/pokerchip/widgets/scanner_button.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:ui_components/ui_components.dart';

//TODO: This might be a duplicate of the QR scanner screen
class PokerchipScannerScreen extends HookConsumerWidget {
  static const routeName = '/pokerchipScannerScreen';

  const PokerchipScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrKey = useMemoized(GlobalKey.new);

    final imagePicker = useMemoized(() => ImagePicker());
    final controller = useMemoized(() => MobileScannerController());
    final barcodeStream = useStream(controller.barcodes);

    useEffect(() {
      final barcode = barcodeStream.data?.barcodes.firstOrNull?.rawValue;
      if (barcode != null) {
        Future.microtask(() async {
          final _ = await context.push(PokerchipBalanceScreen.routeName,
              extra: barcode);
          controller.start();
        });
      }
      return () => controller.stop();
    }, [barcodeStream]);

    return Scaffold(
      body: SafeArea(
        child: Stack(children: [
          //ANCHOR - Scanner
          Container(
            margin: const EdgeInsets.only(top: 28.0),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
              child: MobileScanner(
                key: qrKey,
                controller: controller,
                onDetect: (_) {},
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 45),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Theme(
                      data: Theme.of(context).copyWith(
                        brightness: Brightness.light,
                      ),
                      child: ScannerButton(
                        onTap: () async {
                          controller.stop();
                          context.pop();
                        },
                        icon: AquaIcon.close(
                          color: context.aquaColors.textInverse,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              //ANCHOR - Camera Focus Overlay
              Expanded(
                child: SizedBox.square(
                  dimension: 196.0,
                  child: CustomPaint(
                    painter: PokerchipScannerOverlayPainter(
                      borderColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: 0.0,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //ANCHOR - Gallery Button
                    Theme(
                      data: Theme.of(context).copyWith(
                        brightness: Brightness.light,
                      ),
                      child: ScannerButton(
                        onTap: () async {
                          final image = await imagePicker.pickImage(
                            source: ImageSource.gallery,
                          );
                          final path = image?.path;
                          if (path != null) {
                            await controller.analyzeImage(path);
                          }
                        },
                        icon: AquaIcon.image(
                          color: context.aquaColors.textInverse,
                          size: 24,
                        ),
                      ),
                    ),

                    Theme(
                      data: Theme.of(context).copyWith(
                        brightness: Brightness.light,
                      ),
                      child: ScannerButton(
                        onTap: ref.read(qrScanProvider.notifier).toggleFlash,
                        icon: AquaIcon.lightbulb(
                          color: context.aquaColors.textInverse,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 45),
            ],
          ),
        ]),
      ),
    );
  }
}
