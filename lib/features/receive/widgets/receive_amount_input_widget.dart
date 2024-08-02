import 'package:aqua/config/config.dart';
import 'package:aqua/features/receive/pages/models/receive_asset_extensions.dart';
import 'package:aqua/features/receive/providers/providers.dart';
import 'package:aqua/features/receive/widgets/widgets.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAmountInputWidget extends HookConsumerWidget {
  const ReceiveAmountInputWidget({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // amount
    final amountEntered = ref.watch(receiveAssetAmountProvider);

    // amount input controller
    final controller = useTextEditingController(text: amountEntered);
    controller.addListener(() {
      ref.read(receiveAssetAmountProvider.notifier).state = controller.text;
    });

    // fiat entry toggle
    final isFiatToggled = ref.watch(amountCurrencyProvider) != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BoxShadowCard(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          borderRadius: BorderRadius.circular(12.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              children: [
                SizedBox(height: 24.h),

                //ANCHOR - Title
                Text(
                  context.loc.receiveAssetAmountSheetTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 20.sp,
                      ),
                ),
                SizedBox(height: 24.h),

                //ANCHOR - Amount Input Field
                Container(
                  decoration: Theme.of(context).solidBorderDecoration,
                  child: AmountInputField(
                    asset: asset,
                    controller: controller,
                    isFiatToggled: isFiatToggled,
                  ),
                ),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
        SizedBox(height: 18.h),

        //ANCHOR - Conversion
        if (asset.shouldShowConversionOnReceive) ...[
          ReceiveConversionWidget(asset: asset),
        ],
        SizedBox(height: 18.h),
        if (asset.isLightning) ...[
          BoltzFeeWidget(amountEntered: amountEntered),
        ],
        SizedBox(height: 18.h),
      ],
    );
  }
}
