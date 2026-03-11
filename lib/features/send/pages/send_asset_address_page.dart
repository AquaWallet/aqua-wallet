import 'package:aqua/common/common.dart';
import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide ResponsiveEx;

final _logger = CustomLogger(FeatureFlag.send);

typedef OnSendAddressSubmit = Function(
  SendAssetArguments args,
  String address,
  String amount,
);

/// Calculates the minimum lines needed for an address based on its length
int _calculateMinLinesForAddress(String address) {
  if (address.isEmpty) return 1;

  // Approximate characters per line in the text field
  // This is based on typical address field width and font size
  const int charsPerLine = 30; // Smallest address is tron with 35.

  final lines = (address.length / charsPerLine).ceil();
  return lines.clamp(1, 3); // Min 1 line, max 3 lines
}

class SendAssetAddressPage extends HookConsumerWidget {
  const SendAssetAddressPage({
    super.key,
    required this.onContinuePressed,
    required this.arguments,
  });

  final OnSendAddressSubmit onContinuePressed;
  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = useMemoized(() => sendAssetInputStateProvider(arguments));
    final inputState = ref.watch(provider).valueOrNull;
    final isLoading = ref.watch(provider).isLoading;
    final error = ref.watch(provider).error as ExceptionLocalized?;

    //NOTE: The input state is null for a few milliseconds at the startup,
    //because the input provider accesses the clipboard content asynchronously.
    //This prevents us from being forced to use a nullable inputState variable
    //and needlessly complicate the rest of the screen's state management.
    if (inputState == null) {
      return const SizedBox.shrink();
    }

    final isContinueButtonEnabled = useMemoized(
      () => !isLoading && error == null && !inputState.isAddressFieldEmpty,
      [isLoading, inputState, error],
    );
    final controller =
        useColorCodedTextEditingController(text: inputState.addressFieldText);

    final minLinesForAddress = useMemoized(
      () => _calculateMinLinesForAddress(controller.text),
      [controller],
    );

    useEffect(() {
      if (inputState.isAddressFieldEmpty &&
          !inputState.isClipboardEmpty &&
          inputState.clipboardAddress != null) {
        Future.microtask(() {
          ref.read(provider.notifier).pasteClipboardContent();
        });
      }
      return null;
    }, []);

    final onScanPressed = useCallback(() async {
      ref.read(sendFlowStepProvider.notifier).reset();

      final result = await context.push(
        ScanScreen.routeName,
        extra: ScanArguments(
          qrArguments: QrScannerArguments(
            asset: inputState.asset,
            parseAction: QrScannerParseAction.returnRawValue,
          ),
          textArguments: TextScannerArguments(
            asset: arguments.asset,
            parseAction: TextScannerParseAction.returnRawValue,
            onSuccessAction: TextOnSuccessNavAction.popBack,
          ),
          initialType: ScannerType.qr,
        ),
      );

      // Text Scan
      if (result is String) {
        ref.read(provider.notifier).pasteScannedText(result);
      }
      // QR Scan - handle QrScanState
      else if (result is QrScanState) {
        result.maybeWhen(
          sendAsset: (args) {
            ref.read(provider.notifier).pasteScannedQrCode(args.input);
          },
          unknownQrCode: (code) {
            if (code != null) {
              ref.read(provider.notifier).pasteScannedText(code);
            }
          },
          orElse: () {},
        );
      }
    });

    ref
      ..listen(provider, (_, next) {
        if (next.isLoading) return;
        final newText = next.value?.addressFieldText ?? '';
        if (controller.text != newText) {
          controller.text = newText;
          AquaTooltip.show(
            context,
            anchorKey: SendKeys.sendContinueButton,
            message: context.loc.pastedFromClipboard,
            colors: context.aquaColors,
          );
        }
      })
      ..listen(lightningInvoiceToLbtcSwapProvider(arguments), (prev, next) {
        final wasLightningInvoiceToLbtcSwap = prev?.valueOrNull ?? false;
        final isLightningInvoiceToLbtcSwap = next.valueOrNull ?? false;
        if (!wasLightningInvoiceToLbtcSwap && isLightningInvoiceToLbtcSwap) {
          _logger.debug('Lightning invoice to LBTC swap detected');
          AquaTooltip.show(
            context,
            anchorKey: SendKeys.sendContinueButton,
            message:
                '${context.loc.lightningSendTooltip} \n ${context.loc.learnMore}',
            colors: context.aquaColors,
            maxLines: 2,
            variant: AquaTooltipVariant.normal,
            onToolTipTap: () => ref
                .read(launchUrlProvider.notifier)
                .launchUrl(constants.jan3AquatoAquaTransactionsInfoUrl),
          );
        }
      });

    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + keyboardHeight,
                  ),
                  child: Column(
                    children: [
                      //ANCHOR - Address Input Field
                      AquaTextField(
                        key: SendKeys.sendAddressInput,
                        controller: controller,
                        label: arguments.asset.isLightning
                            ? context.loc.lightningInvoice
                            : context.loc.recipientAddress,
                        showClearInputButton: true,
                        textStyle: AquaAddressTypography.body2,
                        minLines: minLinesForAddress,
                        maxLines: 20,
                        textInputAction: TextInputAction.done,
                        error: controller.text.isNotEmpty && error != null,
                        assistiveText: controller.text.isNotEmpty
                            ? error?.toLocalizedString(context)
                            : null,
                        assistiveTextStyle:
                            context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.error,
                        ),
                        trailingIcon: AquaIcon.scan(
                          size: 18,
                          color: context.aquaColors.textPrimary,
                        ),
                        onTrailingTap: onScanPressed,
                        onChanged: (value) {
                          if (value.isEmpty) {
                            ref.invalidate(provider);
                            ref.read(sendFlowStepProvider.notifier).reset();
                          } else {
                            ref
                                .read(provider.notifier)
                                .updateAddressFieldText(value);
                          }
                        },
                      ),
                      const Spacer(),
                      //ANCHOR - Continue Button
                      AquaButton.primary(
                        key: SendKeys.sendContinueButton,
                        onPressed: isContinueButtonEnabled
                            ? () {
                                // Unfocus the keyboard if it's still pressed
                                FocusScope.of(context).unfocus();
                                onContinuePressed(
                                  SendAssetArguments.fromAsset(
                                      inputState.asset),
                                  inputState.addressFieldText ?? '',
                                  inputState.amountFieldText ?? '',
                                );
                              }
                            : null,
                        text: context.loc.next,
                        isLoading: isLoading,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            //ANCHOR - Scan Button
                            Expanded(
                              child: _BottomActionButton(
                                icon: AquaIcon.scan,
                                label: context.loc.scan,
                                onPressed: onScanPressed,
                              ),
                            ),
                            const SizedBox(width: 24),
                            //ANCHOR - Paste Button
                            Expanded(
                              child: _BottomActionButton(
                                icon: AquaIcon.paste,
                                label: context.loc.paste,
                                onPressed: ref
                                    .read(provider.notifier)
                                    .pasteClipboardContent,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final AquaIconBuilder icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      splashFactory: InkRipple.splashFactory,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon(
              size: 24,
              color: context.aquaColors.textPrimary,
            ),
            const SizedBox(height: 4),
            AquaText.caption2SemiBold(
              text: label,
              color: context.aquaColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}
