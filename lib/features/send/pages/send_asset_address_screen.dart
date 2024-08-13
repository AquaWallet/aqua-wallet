import 'package:aqua/common/common.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/screens/qrscanner/qr_scanner_screen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SendAssetAddressScreen extends HookConsumerWidget {
  const SendAssetAddressScreen({super.key, this.arguments});

  static const routeName = '/sendAssetAddressScreen';

  final SendAssetArguments? arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // watch these to keep them from being disposed throughout send flow
    final asset = ref.watch(sendAssetProvider);
    final address = ref.watch(sendAddressProvider);
    final error = ref.watch(sendAddressErrorProvider);

    // addresss
    final addressInputController = useTextEditingController(text: address);
    useEffect(() {
      // watch `address` provider to fill text field
      if (address != null && address != addressInputController.text) {
        addressInputController.text = address;
      }
      return null;
    }, [address]);

    // check clipboard
    final clipboardCheck =
        ref.watch(checkAndParseClipboardProvider(context)).asData?.value;

    final onScan = useCallback(() async {
      final result = await Navigator.of(context).pushNamed(
        QrScannerScreen.routeName,
        arguments: QrScannerScreenArguments(
          asset: asset,
          // make sure not to parse here, as we'll parse below with `sendAssetInputProvider`
          parseAction: QrScannerParseAction.doNotParse,
          onSuccessAction: QrOnSuccessAction.pull,
        ),
      ) as SendAssetArguments;

      logger.d("[Send][Input] scanned input: ${result.input}");
      if (result.input == null) {
        throw QrScannerInvalidQrParametersException();
      }

      ref.read(sendAssetInputProvider).parseInput(result.input!);
    });

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.sendAssetScreenTitle,
        showActionButton: false,
        backgroundColor: context.colors.addressFieldContainerBackgroundColor,
        iconBackgroundColor:
            context.colors.addressFieldContainerBackgroundColor,
      ),
      // Make sure the Continue button is behind the keyboard
      resizeToAvoidBottomInset: false,
      backgroundColor: context.colors.addressFieldContainerBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            SizedBox(height: 18.h),
            _AssetInfoHeader(asset: asset),
            SizedBox(height: 32.h),
            //ANCHOR - Main Content
            Expanded(
              child: BoxShadowContainer(
                decoration: BoxDecoration(
                  color: context.colors.inverseSurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                  boxShadow: [Theme.of(context).shadow],
                ),
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  children: [
                    SizedBox(height: 24.h),
                    //ANCHOR - Address Input
                    AddressInputView(
                      hintText: context.loc.sendAssetScreenAddressInputHint,
                      controller: addressInputController,
                      onChanged: (_) => ref
                          .read(sendAssetInputProvider)
                          .parseInput(addressInputController.text),
                      onPressed: onScan,
                    ),
                    if (error != null) ...[
                      Row(
                        children: [
                          Text(error.toLocalizedString(context),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error)),
                        ],
                      )
                    ],
                    SizedBox(height: 20.h),
                    //ANCHOR - Paste from Clipboard
                    if (clipboardCheck != null) ...[
                      PasteFromClipboardView(
                        text: clipboardCheck,
                        onPressed: () {
                          ref
                              .read(sendAssetInputProvider)
                              .parseInput(clipboardCheck);
                        },
                      ),
                    ],
                    const Spacer(),
                    if (asset.isInternal) ...[
                      InternalSendMenu(asset: asset),
                      SizedBox(height: 50.h),
                    ],
                    AquaElevatedButton(
                      height: 52.h,
                      onPressed:
                          error == null && address != null && address.isNotEmpty
                              ? () => ref
                                  .read(sendNavigationAmountScreenProvider)
                                  .call(context)
                              : null,
                      child: Text(
                        context.loc.sendAssetAmountScreenContinueButton,
                      ),
                    ),
                    SizedBox(height: 62.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
      padding: EdgeInsets.symmetric(horizontal: 33.w),
      alignment: Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //ANCHOR - Asset Logo
          AssetIcon(
            assetId: asset.isLBTC ? 'Layer2Bitcoin' : asset.id,
            assetLogoUrl: asset.logoUrl,
            size: 72.r,
          ),
          SizedBox(width: 17.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              //ANCHOR - Asset Name
              Text(
                asset.isLBTC ? context.loc.layer2Bitcoin : asset.name,
                textAlign: TextAlign.left,
                style: context.textTheme.headlineLarge?.copyWith(
                  fontSize: 32.sp,
                  letterSpacing: 1,
                ),
              ),
              //ANCHOR - Asset Symbol
              Text(
                asset.isLBTC
                    ? context.loc.internalSendLbtcSubtitle
                    : asset.symbol,
                textAlign: TextAlign.left,
                style: context.textTheme.titleSmall?.copyWith(
                  fontSize: 16.sp,
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
