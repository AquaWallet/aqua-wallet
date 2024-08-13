import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/pages/models/receive_asset_extensions.dart';
import 'package:aqua/features/receive/providers/providers.dart';
import 'package:aqua/features/receive/widgets/widgets.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAmountInputSheet extends HookConsumerWidget {
  const ReceiveAmountInputSheet({
    super.key,
    required this.asset,
    required this.onCancel,
  });

  final Asset asset;
  final Function onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // amount
    final amountEntered =
        useState<String?>(ref.read(receiveAssetAmountProvider));

    // amount input controller
    final controller = useTextEditingController(text: amountEntered.value);
    controller.addListener(() {
      amountEntered.value = controller.text;
    });

    // fiat entry toggle
    final isFiatToggled = ref.watch(amountCurrencyProvider) != null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 21.h),
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          children: [
            SizedBox(height: 18.h),
            //ANCHOR - Title
            Text(
              context.loc.receiveAssetAmountSheetTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 20.sp,
                  ),
            ),
            SizedBox(height: 19.h),
            //ANCHOR - Amount Input
            Container(
              decoration: Theme.of(context).solidBorderDecoration,
              child: AmountInputField(
                asset: asset,
                controller: controller,
                isFiatToggled: isFiatToggled,
              ),
            ),
            SizedBox(height: 15.h),
            if (asset.shouldShowConversionOnReceive) ...[
              ReceiveConversionWidget(
                asset: asset,
                amountStr: amountEntered.value,
              ),
            ],

            SizedBox(height: 18.h),
            //ANCHOR - Confirm Button
            SizedBox(
              width: double.maxFinite,
              child: AquaElevatedButton(
                // disable button if amount is 0
                onPressed: amountEntered.value == null ||
                        amountEntered.value == ''
                    ? null
                    : () {
                        // set amount
                        ref.read(receiveAssetAmountProvider.notifier).state =
                            amountEntered.value;

                        // pop on confirm press if not lightning. if lightning, wait for boltz order to be created successfully then pop
                        if (!asset.isLightning) {
                          Navigator.of(context).pop();
                        }
                      },
                child: Text(
                  context.loc.receiveAssetAmountSheetConfirmButton,
                ),
              ),
            ),
            //ANCHOR - Cancel Button
            SizedBox(height: 20.h),
            if (asset.isLightning) ...[
              SizedBox(
                width: double.maxFinite,
                child: AquaElevatedButton(
                  onPressed: () {
                    onCancel();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    context.loc.cancel,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
