import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/qr_scanner/qr_scanner_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/send/widgets/paste_from_clipboard_view.dart';
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
    // setup
    final disableUI = useState<bool>(false);
    final error = ref.watch(sendAddressErrorProvider);

    // watch these to keep them from being disposed throughout send flow
    final asset = ref.watch(sendAssetProvider);
    final address = ref.watch(sendAddressProvider);

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

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.sendAssetScreenTitle,
        showActionButton: false,
        backgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
      ),
      resizeToAvoidBottomInset:
          false, // Make sure the Continue button is behind the keyboard
      backgroundColor:
          Theme.of(context).colors.addressFieldContainerBackgroundColor,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (error != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child:
                  CustomError(errorMessage: error.toLocalizedString(context)),
            ),
          ],
          Container(
            height: 50.h,
            margin: EdgeInsets.only(
                left: 30.w, top: 12.h, right: 30.w, bottom: 32.h),
            child: AquaElevatedButton(
              onPressed: error == null &&
                      disableUI.value == false &&
                      address != null &&
                      address.isNotEmpty
                  ? () {
                      ref
                          .read(sendNavigationAmountScreenProvider)
                          .call(context);
                    }
                  : null,
              child: Text(
                context.loc.sendAssetAmountScreenContinueButton,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //ANCHOR - Description
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 60.h),
                alignment: Alignment.centerLeft,
                child: Text(
                  context.loc.sendAssetScreenDescription,
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.left,
                ),
              ),

              //ANCHOR - Main Content
              BoxShadowContainer(
                decoration: BoxDecoration(
                  color: Theme.of(context).colors.inverseSurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30.r),
                    topRight: Radius.circular(30.r),
                  ),
                  boxShadow: [Theme.of(context).shadow],
                ),
                padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 40.h),
                child: Column(
                  children: [
                    //ANCHOR - Address Input
                    AddressInputView(
                      hintText: context.loc.sendAssetScreenAddressInputHint,
                      disabled: disableUI.value,
                      controller: addressInputController,
                      onChanged: (_) => ref
                          .read(sendAssetInputProvider)
                          .parseInput(addressInputController.text),
                      onPressed: () async {
                        SendAssetArguments result = await Navigator.of(context)
                            .pushNamed(QrScannerScreen.routeName,
                                arguments: QrScannerScreenArguments(
                                    asset: asset,
                                    throwErrorOnAssetMismatch: true,
                                    // make sure not to parse here, as we'll parse below with `sendAssetInputProvider`
                                    parseAddress: false,
                                    onSuccessAction: QrOnSuccessAction
                                        .pull)) as SendAssetArguments;

                        logger
                            .d("[Send][Input] scanned input: ${result.input}");
                        if (result.input == null) {
                          throw QrScannerInvalidQrParametersException();
                        }

                        ref
                            .read(sendAssetInputProvider)
                            .parseInput(result.input!);
                      },
                    ),
                    SizedBox(height: 40.h),

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
                    SizedBox(height: 460.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
