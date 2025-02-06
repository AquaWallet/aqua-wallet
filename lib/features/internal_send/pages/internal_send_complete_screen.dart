import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/constants.dart';
import 'package:aqua/features/internal_send/internal_send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/utils/utils.dart';
import 'package:lottie/lottie.dart';

class InternalSendCompleteScreen extends HookConsumerWidget {
  static const routeName = '/internalSendCompleteScreen';

  const InternalSendCompleteScreen({super.key, required this.arguments});
  final InternalSendArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: false,
        title: context.loc.internalSend,
      ),
      extendBodyBehindAppBar: true,
      body: arguments.maybeWhen(
        swapSuccess: (state) => _SwapSuccessUi(
          uiModel: ref.read(swapDetailsProvider(state)),
        ),
        pegSuccess: (state) => _PegSuccessUi(
          uiModel: ref.read(pegDetailsProvider(state)),
        ),
        orElse: () => throw ArgumentError('Invalid arguments'),
      ),
    );
  }
}

class _SwapSuccessUi extends StatelessWidget {
  const _SwapSuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          const SizedBox(height: 95.0),
          Lottie.asset(
            animation.tick,
            repeat: false,
            width: 140.0,
            height: 140.0,
            fit: BoxFit.contain,
          ),
          //ANCHOR - Amount Title
          Text(
            context.loc.youveSuccessfullySent,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: .8,
                ),
          ),
          //ANCHOR - Amount
          Text(
            '${uiModel.receiveAmount} ${uiModel.receiveTicker}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 38.0),
          //ANCHOR - Fee Breakdown
          InternalSendFeeBreakdownCard(uiModel: uiModel),
          const SizedBox(height: 20.0),
          //ANCHOR - Transaction ID
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20.0),
                //ANCHOR - Transaction ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.transactionID,
                  value: uiModel.transactionId,
                ),
                const SizedBox(height: 16.0),
                //ANCHOR - Order ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.sideswapOrderID,
                  value: uiModel.sideswapOrderId,
                ),
                const SizedBox(height: 16.0),
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
          const Spacer(),
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
    );
  }
}

class _PegSuccessUi extends StatelessWidget {
  const _PegSuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          const SizedBox(height: 95.0),
          Lottie.asset(
            animation.tick,
            repeat: false,
            width: 140.0,
            height: 140.0,
            fit: BoxFit.contain,
          ),
          //ANCHOR - Amount Title
          Text(
            context.loc.youveSuccessfullySent,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  height: .8,
                ),
          ),
          //ANCHOR - Amount
          Text(
            '${uiModel.receiveAmount} ${uiModel.receiveTicker}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0,
                ),
          ),
          const SizedBox(height: 38.0),
          //ANCHOR - Fee Breakdown
          InternalSendFeeBreakdownCard(uiModel: uiModel),
          const SizedBox(height: 20.0),
          //ANCHOR - Transaction ID
          BoxShadowCard(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20.0),
                //ANCHOR - Transaction ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.transactionID,
                  value: uiModel.transactionId,
                ),
                const SizedBox(height: 16.0),
                //ANCHOR - Order ID
                _ExpandableTransactionDetailItem(
                  label: context.loc.sideswapOrderID,
                  value: uiModel.sideswapOrderId,
                ),
                const SizedBox(height: 16.0),
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
          const Spacer(),
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
    );
  }
}

class _ExpandableTransactionDetailItem extends StatelessWidget {
  const _ExpandableTransactionDetailItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ExpandableContainer(
      padding: const EdgeInsets.only(left: 26.0, right: 20.0),
      title: Text(
        label,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      child: CopyableTextView(
        margin: const EdgeInsetsDirectional.only(top: 4.0, end: 6.0),
        text: value,
      ),
    );
  }
}
