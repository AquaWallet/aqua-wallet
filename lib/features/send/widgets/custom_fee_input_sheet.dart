import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

final allowedInputRegex = RegExp(r'^\d*');

class CustomFeeInputSheet extends HookConsumerWidget {
  const CustomFeeInputSheet(
      {super.key,
      this.minimum,
      this.transactionVsize,
      this.title,
      required this.onConfirm});

  final int? minimum;
  final int? transactionVsize;
  final Function onConfirm;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // amount
    final amountEntered = useState<String?>(null);
    final isBelowMinimum = useMemoized(() {
      try {
        return amountEntered.value != null &&
                amountEntered.value != '' &&
                minimum != null
            ? minimum! > Decimal.parse(amountEntered.value!).toBigInt().toInt()
            : true;
      } catch (e) {
        return true;
      }
    }, [minimum, amountEntered.value]);
    final feeInFiat = ref.watch(
        customFeeInFiatProvider((amountEntered.value, transactionVsize)));

    // amount input controller
    final controller = useTextEditingController(text: amountEntered.value);
    controller.addListener(() {
      amountEntered.value = controller.text;
    });

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
              title ??
                  context
                      .loc.sendAssetReviewScreenConfirmCustomFeeInputSheetTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 20.sp,
                  ),
            ),
            SizedBox(height: 19.h),
            //ANCHOR - Amount Input
            Container(
              decoration: Theme.of(context).solidBorderDecoration,
              child: TextField(
                controller: controller,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 24.sp,
                    ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: false,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(allowedInputRegex),
                  TextInputFormatter.withFunction(
                    (oldValue, newValue) => newValue.copyWith(
                      text: newValue.text.replaceAll(',', '.'),
                    ),
                  ),
                ],
                decoration: Theme.of(context).inputDecoration.copyWith(
                      hintText: context.loc.sendAssetAmountScreenAmountHint,
                      hintStyle:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Theme.of(context).colors.hintTextColor,
                                fontWeight: FontWeight.w400,
                                fontSize: 24.sp,
                              ),
                      border: Theme.of(context).inputBorder,
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'sats/vbyte',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontSize: 24.sp,
                                ),
                          ),
                          SizedBox(width: 23.w),
                        ],
                      ),
                    ),
              ),
            ),
            SizedBox(height: 10.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  feeInFiat != null ? "≈ $feeInFiat" : '',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 18.sp,
                      ),
                ),
                if (minimum != null && isBelowMinimum == true)
                  Text(
                    context.loc
                        .sendAssetReviewScreenConfirmCustomFeeMinimum(minimum!),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 18.sp,
                        color: Colors.red,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
            SizedBox(height: 24.h),
            //ANCHOR - Confirm Button
            SizedBox(
              width: double.maxFinite,
              child: AquaElevatedButton(
                // disable button if amount is 0
                onPressed: amountEntered.value == null ||
                        amountEntered.value == '' ||
                        isBelowMinimum
                    ? null
                    : () {
                        // set amount
                        ref.read(customFeeInputProvider.notifier).state =
                            amountEntered.value;

                        onConfirm();

                        Navigator.of(context).pop();
                      },
                child: Text(
                  context.loc.receiveAssetAmountSheetConfirmButton,
                ),
              ),
            ),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }
}
