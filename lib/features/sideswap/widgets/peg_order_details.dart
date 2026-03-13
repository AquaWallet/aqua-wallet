import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/components/toast/toast.dart';

class PegOrderDetails extends HookConsumerWidget {
  const PegOrderDetails({
    super.key,
    required this.data,
    required this.input,
  });

  final SwapPegReviewModel data;
  final SideswapInputState input;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showToast = useState(true);
    final liquidityWarning =
        ref.watch(swapLiquidityWarningProvider(context.loc));
    return SingleChildScrollView(
      child: Column(
        children: [
          PegReviewInfoCard(
            data: data,
            input: input,
          ),
          const SizedBox(height: 12.0),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const TransactionFeeBreakdownCard(
              args: FeeStructureArguments.sideswap(),
            ),
          ),
          const SizedBox(height: 20.0),
          if (liquidityWarning != null && showToast.value) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: AquaToast(
                title: context.loc.swapLiquidityWarningTitle,
                description: context.loc.swapLiquidityWarningSubtitle,
                variant: AquaToastVariant.normal,
                aquaColors: context.aquaColors,
                onClose: () => showToast.value = false,
                actions: [
                  AquaToastAction(
                    title: context.loc.learnMore,
                    onPressed: () => ref
                        .read(urlLauncherProvider)
                        .open(aquaPegInLiquidityWarningUrl),
                  ),
                ],
              ),
            )
          ],
          SwapSlider(
            onConfirm: () =>
                ref.read(pegProvider.notifier).executeTransaction(),
          ),
          const SizedBox(height: kBottomPadding),
        ],
      ),
    );
  }
}
