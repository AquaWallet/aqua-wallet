import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/features/receive/pages/models/models.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class ReceiveLightningView extends ConsumerWidget {
  final Asset asset;
  final ReceiveBoltzUIState boltzUIState;
  final String? errorMessage;

  const ReceiveLightningView({
    Key? key,
    required this.asset,
    required this.boltzUIState,
    this.errorMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        //ANCHOR - Enter amount text field
        if (boltzUIState == ReceiveBoltzUIState.loading ||
            boltzUIState == ReceiveBoltzUIState.enterAmount) ...[
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
              ))
        ],
      ],
    );
  }
}
