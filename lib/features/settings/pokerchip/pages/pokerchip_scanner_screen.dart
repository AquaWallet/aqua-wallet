import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PokerchipScannerScreen extends HookConsumerWidget {
  static const routeName = '/pokerchipScannerScreen';

  const PokerchipScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePicker = useMemoized(() => ImagePicker());
    final controller = useMemoized(() => MobileScannerController());
    final barcodeStream = useStream(controller.barcodes);

    useEffect(() {
      final barcode = barcodeStream.data?.barcodes.firstOrNull?.rawValue;
      if (barcode != null) {
        Future.microtask(() async {
          final _ = await Navigator.of(context).pushNamed(
            PokerchipBalanceScreen.routeName,
            arguments: barcode,
          );
          controller.start();
        });
      }
      return () => controller.stop();
    }, [barcodeStream]);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.pokerchipScreenTitle,
      ),
      body: SafeArea(
        child: Stack(children: [
          //ANCHOR - Scanner
          Container(
            margin: EdgeInsets.only(top: 28.h),
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.r),
                topRight: Radius.circular(30.r),
              ),
              child: MobileScanner(
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
                dimension: 196.r,
                child: CustomPaint(
                  painter: PokerchipScannerOverlayPainter(
                    borderColor:
                        Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: 0.r,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                height: 52.h,
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                margin: EdgeInsets.only(bottom: 118.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //ANCHOR - Gallery Button
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.r)),
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
                    SizedBox(
                      width: 20.w,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.all(Radius.circular(10.r)),
                      ),
                      child: IconButton(
                        color: Colors.black,
                        icon: const Icon(Icons.flashlight_on_outlined),
                        onPressed: () => controller.toggleTorch(),
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
