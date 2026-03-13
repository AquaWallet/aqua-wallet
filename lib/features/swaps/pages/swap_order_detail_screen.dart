import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class SwapOrderDetailScreen extends HookConsumerWidget {
  static const routeName = '/swapOrderDetailScreen';

  const SwapOrderDetailScreen({super.key, required this.order});
  final SwapOrderDbModel order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref
        .watch(swapStatusProvider(SwapStatusParams.fromOrder(order)))
        .valueOrNull;

    final depositAmountStr =
        order.depositAmount.isEmpty ? '-' : order.depositAmount;
    final settleAmountStr =
        order.settleAmount == null || order.settleAmount!.isEmpty
            ? '-'
            : order.settleAmount!;

    final createdAtStr = order.createdAt.mmMdyyyyHmma();
    final expiresAtStr = order.expiresAt?.mmMdyyyyHmma() ?? '-';

    final fromAssetName = SwapAssetExt.fromId(order.fromAsset).name;
    final toAssetName = SwapAssetExt.fromId(order.toAsset).name;

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
              if (status != null) ...[
                AquaListItem(
                  title: context.loc.status,
                  subtitleTrailing:
                      (status.orderStatus ?? SwapOrderStatus.unknown)
                          .toLocalizedString(context),
                ),
                AquaDivider(colors: context.aquaColors),
              ],
              //ANCHOR - Service
              AquaListItem(
                title: context.loc.service,
                subtitleTrailing: order.serviceType.displayName,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Created At
              AquaListItem(
                title: context.loc.createdAt,
                subtitleTrailing: createdAtStr,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Expires At
              AquaListItem(
                title: context.loc.expiresAt,
                subtitleTrailing: expiresAtStr,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - From Asset
              AquaListItem(
                title: context.loc.from,
                subtitleTrailing: fromAssetName,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - To Asset
              AquaListItem(
                title: context.loc.to,
                subtitleTrailing: toAssetName,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Deposit Amount
              AquaListItem(
                title: context.loc.depositAmount,
                subtitleTrailing: depositAmountStr,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Settle Amount
              AquaListItem(
                title: context.loc.settleAmount,
                subtitleTrailing: settleAmountStr,
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Order ID
              AquaListItem(
                title: context.loc.orderId,
                subtitle: order.orderId,
                iconTrailing: AquaIcon.copy(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
                onTap: () => context.copyToClipboard(
                  order.orderId,
                  successMessage: context.loc.swapIdCopiedSnackbar,
                ),
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Deposit Address
              AquaListItem(
                title: context.loc.depositAddress,
                contentWidget: AquaColoredText(
                  text: order.depositAddress,
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
                onTap: () => context.copyToClipboard(
                  order.depositAddress,
                  successMessage: context.loc.depositAddressCopied,
                ),
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Settle Address
              AquaListItem(
                title: context.loc.settleAddress,
                contentWidget: AquaColoredText(
                  text: order.settleAddress,
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
                onTap: () => context.copyToClipboard(
                  order.settleAddress,
                  successMessage: context.loc.settleAddressCopied,
                ),
              ),
              AquaDivider(colors: context.aquaColors),
              //ANCHOR - Contact Support
              AquaListItem(
                title: context.loc.commonContactSupport,
                titleColor: context.aquaColors.accentBrand,
                iconTrailing: AquaIcon.externalLink(
                  size: 18,
                  color: context.aquaColors.textSecondary,
                ),
                onTap: () => ref
                    .read(urlLauncherProvider)
                    .open(order.serviceType.serviceUrl(orderId: order.orderId)),
              ),
            ],
          ),
        ),
      )),
    );
  }
}
