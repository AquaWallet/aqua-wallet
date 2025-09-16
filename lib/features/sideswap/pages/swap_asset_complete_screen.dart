import 'package:coin_cz/features/auth/auth_wrapper.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/config/constants/animations.dart' as animation;
import 'package:coin_cz/constants.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:lottie/lottie.dart';

class SwapAssetCompleteScreen extends HookConsumerWidget {
  static const routeName = '/swapAssetCompleteScreen';

  const SwapAssetCompleteScreen({super.key, required this.arguments});
  final SwapStateSuccess arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiModel = ref.read(swapDetailsProvider(arguments));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: false,
        title: context.loc.swaps,
      ),
      body: _SuccessUi(uiModel: uiModel),
    );
  }
}

class _SuccessUi extends StatelessWidget {
  const _SuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26.0),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 18.0),
            Lottie.asset(
              animation.tick,
              repeat: false,
              width: 100.0,
              height: 100.0,
              fit: BoxFit.cover,
            ),
            const SizedBox(height: 7.0),
            //ANCHOR - Amount Title
            Text(
              context.loc.swapScreenSuccessAmountTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 10.0),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //ANCHOR - Amount
                //TODO: asset amount widget
                Text(
                  uiModel.receiveAmount,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(width: 6.0),
                //ANCHOR - Symbol
                Text(
                  uiModel.receiveTicker,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AquaColors.graniteGray,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            //ANCHOR - Transaction Info
            BoxShadowCard(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 22.0),
                  //ANCHOR - Amount
                  //TODO:- asset amount widget
                  TransactionInfoItem(
                    label: context.loc.swapFrom,
                    value: '${uiModel.deliverAmount} ${uiModel.deliverTicker}',
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  ),
                  const SizedBox(height: 18),
                  //ANCHOR - Network Fee
                  TransactionInfoItem(
                    label: context.loc.sendAssetCompleteScreenFeeLabel,
                    value: uiModel.networkFee,
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  ),
                  const SizedBox(height: 18.0),
                  //ANCHOR - Notes
                  // ExpandableContainer(
                  //   padding: EdgeInsets.only(left: 26.0, right: 6.0),
                  //   title: Text(
                  //     context.loc.myNotes,
                  //     style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  //           color: Theme.of(context).colorScheme.onSurface,
                  //           fontWeight: FontWeight.w400,
                  //         ),
                  //   ),
                  //   child: Container(
                  //     padding: EdgeInsets.only(bottom: 18.0),
                  //     child: Text(
                  //       uiModel.note ?? '',
                  //       textAlign: TextAlign.start,
                  //       style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  //             color: Theme.of(context).colors.onBackground,
                  //             fontWeight: FontWeight.w400,
                  //           ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),
            //ANCHOR - Transaction ID
            BoxShadowCard(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 9.0),
                  //ANCHOR - Transaction ID
                  ExpandableContainer(
                    padding: const EdgeInsets.only(left: 26.0, right: 6.0),
                    title: Text(
                      context.loc.transactionID,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                    ),
                    child: CopyableTextView(text: uiModel.transactionId),
                  ),
                  //ANCHOR - Time
                  TransactionInfoItem(
                    label: context.loc.time,
                    value: uiModel.time,
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  ),
                  const SizedBox(height: 18.0),
                  //ANCHOR - Date
                  TransactionInfoItem(
                    label: context.loc.date,
                    value: uiModel.date,
                    padding: const EdgeInsets.symmetric(horizontal: 26.0),
                  ),
                  const SizedBox(height: 26.0),
                ],
              ),
            ),
            const SizedBox(height: 18.0),
            //ANCHOR - Button
            SizedBox(
              width: double.maxFinite,
              child: BoxShadowElevatedButton(
                onPressed: () => context.go(AuthWrapper.routeName),
                child: Text(
                  context.loc.done,
                ),
              ),
            ),
            const SizedBox(height: kBottomPadding),
          ],
        ),
      ),
    );
  }
}
