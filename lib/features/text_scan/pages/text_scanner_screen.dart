import 'package:aqua/features/lightning/pages/lnurl_withdraw_screen.dart';
import 'package:aqua/features/send/pages/send_asset_screen.dart';
import 'package:aqua/features/text_scan/models/text_scan_arguments.dart';
import 'package:aqua/features/text_scan/providers/text_scan_provider.dart';
import 'package:aqua/features/text_scan/providers/text_scan_state_provider.dart';
import 'package:aqua/logger.dart';
import 'package:camera/camera.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/utils/utils.dart';

import '../../send/pages/address_selection_screen.dart';

final _logger = CustomLogger(FeatureFlag.textScan);

class TextScannerScreen extends HookConsumerWidget {
  static const routeName = '/textScannerScreen';

  final TextScannerArguments arguments;

  const TextScannerScreen({super.key, required this.arguments});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      return () {
        ref.read(textScanProvider.notifier).resetCamera();
        ref.invalidate(textScanStateProvider(arguments));
      };
    }, []);

    final initFuture = useMemoized(() async {
      final cameras = await availableCameras();
      await ref.read(textScanProvider.notifier).initCamera(cameras);
    });

    final state = ref.watch(textScanProvider);

    final showExceptionDialog = useCallback((String alertSubtitle) {
      showDialog<CustomAlertDialog>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => CustomAlertDialog(
          title: context.loc.scanTextDefaultError,
          subtitle: alertSubtitle,
          controlWidgets: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  dialogContext.pop();
                  ref.read(textScanProvider.notifier).resetCamera();
                },
                child: Text(context.loc.tryAgain),
              ),
            ),
          ],
        ),
      );
    });

    ref.listen(
      textScanStateProvider(arguments),
      (previous, next) {
        next.when(
          data: (data) => data.maybeWhen(
            unknownText: (raw) => showExceptionDialog(raw),
            rawValue: (raw) => Navigator.of(context).pop(raw),
            pullSendAsset: (args) => Navigator.of(context).pop(args),
            pushSendAsset: (args) async {
              _logger.debug('pushSendAsset: $args');
              await context.push(SendAssetScreen.routeName, extra: args);
            },
            lnurlWithdraw: (args) => context.push(
              LnurlWithdrawScreen.routeName,
              extra: args,
            ),
            multipleRawValue: (addresses) async {
              _logger.debug('multipleRawValue: $addresses');
              final selectedAddress = await context.push<dynamic>(
                AddressSelectionScreen.routeName,
                extra: addresses,
              );
              if (selectedAddress != null && context.mounted) {
                Navigator.of(context).pop(selectedAddress);
              }
            },
            addressSelection: (addresses) async {
              _logger.debug('addressSelection: $addresses');
              final selectedAddress = await context.push<String?>(
                AddressSelectionScreen.routeName,
                extra: addresses,
              );

              if (selectedAddress != null && context.mounted) {
                ref
                    .read(textScanStateProvider(arguments).notifier)
                    .processSingleAddress(selectedAddress, arguments);
              }
            },
            orElse: () {},
          ),
          error: (error, stack) => showExceptionDialog(error.toString()),
          loading: () {},
        );
      },
    );

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (didPop) {
          ref.read(textScanProvider.notifier).resetCamera();
          ref.invalidate(textScanStateProvider(arguments));
        }
      },
      child: Scaffold(
        body: FutureBuilder<void>(
          future: initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AsyncLoading && state.value == null) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.hasError) {
              return Center(
                child: Text(
                  state.error.toString(),
                  style: TextStyle(color: context.colorScheme.error),
                ),
              );
            }

            final controller =
                ref.read(textScanProvider.notifier).cameraController;
            if (controller == null || !controller.value.isInitialized) {
              return Center(child: Text(context.loc.cameraIsNotAvailable));
            }

            return Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      child: CameraPreview(controller),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(textScanProvider.notifier)
                              .takeSnapshotAndRecognize();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.scanBottom,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          minimumSize: const Size(116, 40),
                        ),
                        child: Text(context.loc.buttonScanText),
                      ),
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
