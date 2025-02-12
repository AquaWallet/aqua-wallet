import 'dart:math';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

class TransactionFeeBreakdownCard extends ConsumerWidget {
  const TransactionFeeBreakdownCard({
    super.key,
    required this.args,
  });

  final FeeStructureArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fees = ref.watch(transactionFeeStructureProvider(args));

    return BoxShadowCard(
      color: context.colors.altScreenSurface,
      bordered: true,
      borderColor: context.colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: context.adaptiveDouble(mobile: 18, smallMobile: 14),
          vertical: context.adaptiveDouble(mobile: 14, smallMobile: 10),
        ),
        child: fees.maybeWhen(
          data: (data) => data.maybeMap(
            sideswapInstantSwap: (data) => _InstantSwapInfo(fees: data),
            sideswapPegIn: (data) => _PegInInfo(fees: data),
            sideswapPegOut: (data) => _PegOutInfo(fees: data),
            bitcoinSend: (data) => _BitcoinSendInfo(fees: data),
            liquidSend: (data) => _LiquidSendInfo(fees: data),
            liquidTaxiSend: (data) => _LiquidTaxiSendInfo(fees: data),
            // TODO Add remaining fee brakdown types
            // boltzReceive: (data) => _BoltzReceiveInfo(fees: data),
            boltzSend: (data) => _BoltzSendInfo(fees: data),
            usdtSwap: (data) => _USDtSwapInfo(fees: data),
            orElse: () => const SizedBox.shrink(),
          ),
          orElse: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}

class _USDtSwapInfo extends ConsumerWidget {
  const _USDtSwapInfo({
    required this.fees,
  });

  final USDtSwapFee fees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapService = ref.watch(preferredUsdtSwapServiceProvider).valueOrNull;
    final swapServiceName = swapService?.displayName;

    return Column(
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              width: 2,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _CollapsableFeeBreakdownItem(
                title: context.loc.totalFees,
                value: '\$${fees.totalFees}',
                children: [
                  _FeeBreakdownItem(
                    title: '${context.loc.swapFee(swapServiceName ?? '')} '
                        '(${fees.serviceFeePercentage}%)',
                    value: '\$${fees.serviceFee}',
                  ),
                  const SizedBox(height: 4),
                  //TODO: Network fee comes back for Changelly but doesn't seem to calculate in the settleAmount. Need to revise. Need to revise.
                  if (fees.networkFee > 0) ...[
                    _FeeBreakdownItem(
                      title: context.loc.networkFees,
                      value: '\$${fees.networkFee}',
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InstantSwapInfo extends StatelessWidget {
  const _InstantSwapInfo({
    required this.fees,
  });

  final SideswapInstantSwapFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              width: 2.0,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewSideswapServiceFee,
                value: '${fees.swapFeePercentage}%',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.networkFees,
                value:
                    '${fees.estimatedFee.toStringAsFixed(2)} ${SupportedDisplayUnits.sats.value}',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewCurrentRate,
                value: context.loc.satsPerVbyte(fees.feeRate),
              ),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _PegInInfo extends StatelessWidget {
  const _PegInInfo({
    required this.fees,
  });

  final SideswapPegInFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              width: 2.0,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewSideswapServiceFee,
                value: '${fees.swapFeePercentage}%',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.pegBitcoinNetworkFees,
                value: fees.estimatedBtcFee.toString(),
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.pegLiquidNetworkFees,
                value: fees.estimatedLbtcFee.toString(),
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.currentBitcoinRate,
                value: context.loc.satsPerVbyte(fees.btcFeeRate),
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.currentLiquidRate,
                value: context.loc.satsPerVbyte(fees.lbtcFeeRate),
              ),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _PegOutInfo extends StatelessWidget {
  const _PegOutInfo({
    required this.fees,
  });

  final SideswapPegOutFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              width: 2.0,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewSideswapServiceFee,
                value: '${fees.swapFeePercentage}%',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.pegBitcoinNetworkFees,
                value: fees.estimatedBtcFee.toString(),
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.pegLiquidNetworkFees,
                value: fees.estimatedLbtcFee.toString(),
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.currentBitcoinRate,
                value: context.loc.satsPerVbyte(fees.btcFeeRate),
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.currentLiquidRate,
                value: context.loc.satsPerVbyte(fees.lbtcFeeRate),
              ),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _BitcoinSendInfo extends StatelessWidget {
  const _BitcoinSendInfo({
    required this.fees,
  });

  final BitcoinSendFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              width: 2.0,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.networkFees,
                value: '${fees.estimatedFee} sats',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewCurrentRate,
                value: context.loc.satsPerVbyte(fees.feeRate),
              ),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiquidSendInfo extends StatelessWidget {
  const _LiquidSendInfo({
    required this.fees,
  });

  final LiquidSendFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              width: 2.0,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.networkFees,
                value: '${fees.estimatedFee} sats',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.internalSendReviewCurrentRate,
                value: context.loc.satsPerVbyte(fees.feeRate),
              ),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _BoltzSendInfo extends StatelessWidget {
  const _BoltzSendInfo({
    required this.fees,
  });

  final BoltzSendFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              width: 2,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.boltzServiceFee,
                value: '${fees.swapFeePercentage * 100}%',
              ),
              const SizedBox(height: 14),
              _FeeBreakdownItem(
                title: context.loc.liquidNetworkFees,
                value: '${fees.estimatedOnchainFee} sats',
              ),
              const SizedBox(height: 14),
              _FeeBreakdownItem(
                title: context.loc.currentLiquidRate,
                value: context.loc.satsPerVbyte(
                  fees.onchainFeeRate / kVbPerKb,
                ),
              ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiquidTaxiSendInfo extends StatelessWidget {
  const _LiquidTaxiSendInfo({
    required this.fees,
  });

  final LiquidTaxiSendFee fees;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(
              width: 2.0,
              color: context.colors.cardOutlineColor,
            ),
          ),
          child: Column(
            children: [
              _FeeBreakdownItem(
                title: context.loc.estimatedLiquidNetworkFee,
                value: '${fees.estimatedLbtcFee} sats',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.estimatedTaxiFee,
                value: '${fees.estimatedUsdtFee.toStringAsFixed(2)} USD',
              ),
              const SizedBox(height: 14.0),
              _FeeBreakdownItem(
                title: context.loc.liquidNetworkRate,
                value: context.loc.satsPerVbyte(fees.lbtcFeeRate),
              ),
              const SizedBox(height: 6.0),
            ],
          ),
        ),
      ],
    );
  }
}

class _CollapsableFeeBreakdownItem extends HookWidget {
  const _CollapsableFeeBreakdownItem({
    required this.title,
    this.value,
    required this.children,
  });

  final String title;
  final String? value;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final isExpanded = useState<bool>(false);

    return Column(
      children: [
        GestureDetector(
          onTap: () => isExpanded.value = !isExpanded.value,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.onBackground,
                  fontFamily: UiFontFamily.helveticaNeue,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 2),
              TightExpandIcon(
                size: 20,
                onPressed: null,
                padding: EdgeInsets.zero,
                disabledColor: context.colors.onBackground,
                expandedColor: context.colors.onBackground,
                isExpanded: isExpanded.value,
              ),
              const Spacer(),
              Text(
                value ?? '',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.onBackground,
                  fontFamily: UiFontFamily.helveticaNeue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          height: isExpanded.value ? null : 0,
          padding: const EdgeInsetsDirectional.only(start: 14),
          duration: const Duration(milliseconds: 300),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }
}

class _FeeBreakdownItem extends StatelessWidget {
  const _FeeBreakdownItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.onBackground,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: context.colors.onBackground,
            fontFamily: UiFontFamily.helveticaNeue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _RefreshButton extends ConsumerWidget {
  const _RefreshButton({
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox.square(
      dimension: 32.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: 14.0,
            height: 14.0,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4.0),
              border: Theme.of(context).isLight
                  ? Border.all(
                      color: Theme.of(context).colors.divider,
                      width: 2.0,
                    )
                  : null,
            ),
            child: Transform.rotate(
              angle: pi / 2,
              child: SvgPicture.asset(
                Svgs.walletExchange,
                fit: BoxFit.scaleDown,
                width: 14.0,
                height: 14.0,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colors.onBackground,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        //ANCHOR - Title
        Text(
          context.loc.fees,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colors.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                // height: 1.5.0,
              ),
        ),
        SizedBox(
          height: context.adaptiveDouble(mobile: 16.0, smallMobile: 10.0),
        ),
      ],
    );
  }
}
