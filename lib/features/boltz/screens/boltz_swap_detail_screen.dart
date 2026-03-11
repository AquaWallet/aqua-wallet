import 'dart:convert';

import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:aqua/utils/extensions/date_time_ext.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class BoltzSwapDetailScreen extends HookConsumerWidget {
  static const routeName = '/boltzSwapDetailScreen';

  const BoltzSwapDetailScreen({super.key, required this.swap});

  final BoltzSwapDbModel swap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formattedAmount = swap.amountFromInvoice != null
        ? ref.watch(currencyFormatProvider(0)).format(swap.amountFromInvoice!)
        : null;
    final amountWithUnit = formattedAmount != null
        ? '$formattedAmount ${SupportedDisplayUnits.sats.value}'
        : null;
    final refundData = useFuture(
      ref.read(boltzSubmarineSwapProvider.notifier).getRefundData(swap),
    );

    final onSwapRefund = useCallback(() {
      final jsonString = jsonEncode(refundData.data?.toJson());
      context.copyToClipboard(jsonString);
    }, [refundData.data]);

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.swapOrder,
        showBackButton: true,
        colors: context.aquaColors,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Status
                if (swap.lastKnownStatus != null) ...[
                  AquaListItem(
                    title: context.loc.status,
                    subtitleTrailing:
                        swap.lastKnownStatus?.label(context) ?? '',
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
                //ANCHOR - Amount
                if (swap.amountFromInvoice != null) ...[
                  AquaListItem(
                    title: context.loc.boltzInvoiceAmount,
                    subtitleTrailing: amountWithUnit,
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
                //ANCHOR - Created
                if (swap.createdAt != null) ...[
                  AquaListItem(
                    title: context.loc.created,
                    subtitleTrailing: swap.createdAt?.mmMdyyyyHmma() ?? '',
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
                //ANCHOR - Timeout Block Height
                AquaListItem(
                  title: context.loc.boltzTimeoutBlockHeight,
                  subtitleTrailing: swap.locktime.toString(),
                ),
                AquaDivider(colors: context.aquaColors),
                //ANCHOR - Boltz ID
                AquaListItem(
                  title: context.loc.boltzId,
                  contentWidget: Text(
                    swap.boltzId,
                    style: AquaAddressTypography.body2.copyWith(
                      color: context.aquaColors.textPrimary,
                    ),
                  ),
                  iconTrailing: AquaIcon.copy(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  onTap: () => context.copyToClipboard(swap.invoice),
                ),
                AquaDivider(colors: context.aquaColors),
                //ANCHOR - Invoice
                AquaListItem(
                  title: context.loc.lightningInvoice,
                  contentWidget: AquaColoredText(
                    text: swap.invoice,
                    maxLines: 2,
                    style: AquaAddressTypography.body2.copyWith(
                      color: context.aquaColors.textSecondary,
                    ),
                    colorType: ColoredTextEnum.coloredIntegers,
                    shouldWrap: true,
                  ),
                  iconTrailing: AquaIcon.copy(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  onTap: () => context.copyToClipboard(swap.invoice),
                ),
                AquaDivider(colors: context.aquaColors),
                //ANCHOR - Claim Transaction ID
                if (swap.kind == SwapType.reverse) ...[
                  AquaListItem(
                    title: context.loc.boltzClaimTx,
                    subtitle: swap.claimTxId ?? context.loc.notAvailable,
                    iconTrailing: AquaIcon.copy(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                    onTap: swap.claimTxId != null
                        ? () => context.copyToClipboard(swap.claimTxId!)
                        : null,
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
                //ANCHOR - Refund Transaction ID
                if (swap.kind == SwapType.submarine) ...[
                  AquaListItem(
                    title: context.loc.boltzRefundTx,
                    subtitle: swap.refundTxId ?? context.loc.notAvailable,
                    iconTrailing: AquaIcon.copy(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                    onTap: swap.refundTxId != null
                        ? () => context.copyToClipboard(swap.refundTxId!)
                        : null,
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
                //ANCHOR - Boltz Data Button
                AquaListItem(
                  title: context.loc.boltzCopySwapData,
                  titleColor: context.aquaColors.accentBrand,
                  iconTrailing: AquaIcon.copy(
                    size: 18,
                    color: context.aquaColors.textSecondary,
                  ),
                  onTap: () =>
                      context.copyToClipboard(swap.toJson().toString()),
                ),
                AquaDivider(colors: context.aquaColors),
                //ANCHOR - Claim Swap Button
                if (swap.kind == SwapType.reverse &&
                    swap.claimTxId == null) ...[
                  AquaListItem(
                    title: context.loc.boltzClaimSwap,
                    titleColor: context.aquaColors.accentBrand,
                    iconTrailing: AquaIcon.chevronRight(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                    onTap: () => ref
                        .read(boltzSwapSettlementServiceProvider)
                        .claimBySwapId(swap.boltzId),
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
                //ANCHOR - Refund Swap Button
                if (swap.kind == SwapType.submarine &&
                    swap.refundTxId == null) ...[
                  AquaListItem(
                    title: context.loc.boltzCopyRefundData,
                    titleColor: context.aquaColors.accentBrand,
                    iconTrailing: AquaIcon.chevronRight(
                      size: 18,
                      color: context.aquaColors.textSecondary,
                    ),
                    onTap: refundData.data != null ? onSwapRefund : null,
                  ),
                  AquaDivider(colors: context.aquaColors),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
