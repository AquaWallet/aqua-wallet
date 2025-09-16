import 'package:coin_cz/features/qr_scan/qr_scan.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PokerchipScannerScreen extends HookConsumerWidget {
  static const routeName = '/pokerchipScannerScreen';

  const PokerchipScannerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qrKey = useMemoized(GlobalKey.new);

    ref.listen(qrScanProvider, (_, data) {
      final isQr = !data.isLoading && (data.valueOrNull?.isNotEmpty ?? false);
      if (isQr) {
        Future.microtask(() async {
          final _ = await context.push(
            PokerchipBalanceScreen.routeName,
            extra: data.value,
          );
          ref.read(qrScanProvider.notifier).restartCamera();
        });
      }
    });

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
                controller: ref.read(qrScanProvider.notifier).controller,
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
                        onPressed: ref
                            .read(qrScanProvider.notifier)
                            .scanImageForBarcode,
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
