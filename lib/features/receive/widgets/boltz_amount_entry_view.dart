import 'package:coin_cz/common/widgets/custom_error.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/receive/receive.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';

class BoltzAmountEntryView extends ConsumerWidget {
  final Asset asset;

  const BoltzAmountEntryView({
    super.key,
    required this.asset,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = ref.watch(boltzReverseSwapUiErrorProvider);
    final boltzUiState = ref.watch(boltzReverseSwapProvider);

    return Column(
      children: [
        //ANCHOR - Enter amount text field
        if (boltzUiState.isAmountEntry) ...[
          const SizedBox(height: 40.0),
          ReceiveAmountInputWidget(asset: asset),
          const SizedBox(height: 21.0),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(children: [
              CustomError(errorMessage: errorMessage),
            ]),
          ),
        ]
        //ANCHOR - "Generating Invoice"
        else ...[
          const SizedBox(height: 24.0),
          SizedBox(
            height: 300.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(context.loc.receiveLightningViewGeneratingStatusMessage,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(
                  height: 20.0,
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
