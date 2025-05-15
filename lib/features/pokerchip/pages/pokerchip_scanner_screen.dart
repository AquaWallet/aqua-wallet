import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.bitcoinChip,
      ),
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
              const Spacer(),
              //ANCHOR - Camera Focus Overlay
              SizedBox.square(
                dimension: 196.0,
                child: CustomPaint(
                  painter: PokerchipScannerOverlayPainter(
                    borderColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: 0.0,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 52.0,
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                margin: const EdgeInsets.only(bottom: 118.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //ANCHOR - Gallery Button
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: IconButton(
                        color: Colors.black,
                        icon: const Icon(Icons.photo_library_outlined),
                        onPressed: () async {
                          final image = await imagePicker.pickImage(
                              source: ImageSource.gallery);
                          final path = image?.path;
                          if (path != null) {
                            await controller.analyzeImage(path);
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      width: 20.0,
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.0)),
                      ),
                      child: IconButton(
                        color: Colors.black,
                        icon: const Icon(Icons.flashlight_on_outlined),
                        onPressed:
                            ref.read(qrScanProvider.notifier).toggleFlash,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}
