import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/qr_scan/qr_scan.dart';
import 'package:aqua/features/text_scan/text_scan.dart';
import 'package:aqua/features/scan/scan.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetAddressPage extends HookConsumerWidget {
  const SendAssetAddressPage({
    super.key,
    required this.onContinuePressed,
    required this.arguments,
  });

  final Function(SendAssetArguments args, String address, String amount)
      onContinuePressed;
  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = useMemoized(() => sendAssetInputStateProvider(arguments));
    final inputState = ref.watch(provider).valueOrNull;
    final isLoading = ref.watch(provider).isLoading;
    final error = ref.watch(provider).error as ExceptionLocalized?;

    if (inputState == null) {
      if (error != null) {
        return Text(
          error.toLocalizedString(context),
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.error,
          ),
        );
      }

      return const LoadingIndicator();
    }

    final isContinueButtonEnabled = useMemoized(
      () => !isLoading && error == null && !inputState.isAddressFieldEmpty,
      [isLoading, inputState, error],
    );
    final controller =
        useTextEditingController(text: inputState.addressFieldText);

    final onScanPressed = useCallback(() async {
      final result = await context.push<dynamic>(
        ScanScreen.routeName,
        extra: ScanArguments(
          qrArguments: QrScannerArguments(
            asset: inputState.asset,
            parseAction: QrScannerParseAction.attemptToParse,
            onSuccessAction: QrOnSuccessNavAction.popBack,
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
      // QR Scan
      else if (result is SendAssetArguments) {
        ref.read(provider.notifier).pasteScannedQrCode(result.input);
      }
    });

    ref.listen(provider, (_, next) {
      controller.text = next.value?.addressFieldText ?? '';
    });

    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        const SizedBox(height: 18.0),
        //ANCHOR - Asset Info Header
        _AssetInfoHeader(asset: inputState.asset),
        const SizedBox(height: 32.0),
        //ANCHOR - Main Content
        Expanded(
          child: BoxShadowContainer(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            decoration: BoxDecoration(
              color: context.colors.inverseSurfaceColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
              boxShadow: [Theme.of(context).shadow],
            ),
            child: Column(
              children: [
                const SizedBox(height: 24.0),
                //ANCHOR - Address Input
                AddressInputView(
                  hintText: context.loc.sendAssetScreenAddressInputHint,
                  controller: controller,
                  onScanPressed: onScanPressed,
                  onChanged: ref.read(provider.notifier).updateAddressFieldText,
                ),
                //ANCHOR - Error
                if (error != null) ...{
                  const SizedBox(height: 8.0),
                  Row(children: [
                    Text(
                      error.toLocalizedString(context),
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.error,
                      ),
                    ),
                  ])
                },
                const SizedBox(height: 20.0),
                //ANCHOR - Paste from Clipboard
                if (!inputState.isClipboardEmpty) ...[
                  PasteFromClipboardView(
                    text: inputState.clipboardAddress!,
                    onPressed:
                        ref.read(provider.notifier).pasteClipboardContent,
                  ),
                ],
                const Spacer(),
                //ANCHOR - Internal Send Menu
                if (inputState.asset.isInternal) ...[
                  InternalSendMenu(asset: inputState.asset),
                  const SizedBox(height: 50.0),
                ],
                //ANCHOR - Continue Button
                AquaElevatedButton(
                  height: 52.0,
                  onPressed: isContinueButtonEnabled
                      ? () => onContinuePressed(
                            SendAssetArguments.fromAsset(inputState.asset),
                            inputState.addressFieldText ?? '',
                            inputState.amountFieldText ?? '',
                          )
                      : null,
                  child: Text(context.loc.continueLabel),
                ),
                const SizedBox(height: 62.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AssetInfoHeader extends StatelessWidget {
  const _AssetInfoHeader({
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 33.0),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //ANCHOR - Asset Logo
          AssetIcon(
            assetId: asset.isLBTC ? liquidId : asset.id,
            assetLogoUrl: asset.isLBTC ? Svgs.liquidAsset : asset.logoUrl,
            size: context.adaptiveDouble(smallMobile: 50, mobile: 72),
          ),
          const SizedBox(width: 17.0),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              //ANCHOR - Asset Name
              Text(
                asset.isLBTC ? context.loc.layer2Bitcoin : asset.name,
                textAlign: TextAlign.left,
                style: context.textTheme.headlineLarge?.copyWith(
                  fontSize: context.adaptiveDouble(smallMobile: 22, mobile: 32),
                  letterSpacing: 1,
                ),
              ),
              //ANCHOR - Asset Symbol
              Text(
                asset.isLBTC
                    ? context.loc.internalSendLbtcSubtitle
                    : asset.displayName,
                textAlign: TextAlign.left,
                style: context.textTheme.titleSmall?.copyWith(
                  fontSize: 16.0,
                  letterSpacing: 1,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
