import 'package:coin_cz/common/widgets/custom_error.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/receive/receive.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class ReceiveLightningView extends ConsumerWidget {
  final Asset asset;

  const ReceiveLightningView({
    super.key,
    required this.asset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // error message
    final errorMessage = ref.watch(boltzReverseSwapUiErrorProvider);

    // boltz ui state
    final boltzUiState = ref.watch(boltzReverseSwapProvider);

    return Column(
      children: [
        //ANCHOR - Enter amount text field
        if (boltzUiState.isAmountEntry) ...[
          SizedBox(height: 40.h),
          ReceiveAmountInputWidget(asset: asset),
          SizedBox(height: 21.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(children: [
              CustomError(errorMessage: errorMessage),
            ]),
          ),
        ]
        //ANCHOR - "Generating Invoice"
        else ...[
          SizedBox(height: 24.h),
          SizedBox(
            height: 300.h,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(context.loc.receiveLightningViewGeneratingStatusMessage,
                    style: Theme.of(context).textTheme.titleMedium),
                SizedBox(
                  height: 20.h,
                ),
                const CircularProgressIndicator(),
              ],
            ),
          )
        ],
      ],
    );
  }
}
