import 'package:aqua/features/depix/pages/depix_pix_qr_view.dart';
import 'package:aqua/features/depix/providers/depix_deposit_provider.dart';
import 'package:aqua/features/depix/providers/depix_amount_formatter_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class DepixDepositQrPage extends HookConsumerWidget {
  const DepixDepositQrPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final depositState = ref.watch(depixDepositProvider);

    return depositState.when(
      loading: () => const _DepixDepositQrSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result == null) return const SizedBox.shrink();
        return _DepixDepositQrContent(result: result);
      },
    );
  }
}

class _DepixDepositQrContent extends HookConsumerWidget {
  const _DepixDepositQrContent({required this.result});

  final DepixDepositResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.aquaColors;
    final formatter = ref.watch(depixAmountFormatterProvider);

    final amountFormatted = formatter.formatBrlCents(
      result.amountBrlCents,
      withSymbol: true,
    );

    final feeFormatted = result.feeBrlCents > 0
        ? formatter.formatBrlCents(
            result.feeBrlCents,
            withSymbol: true,
          )
        : context.loc.depixDepositEulenFeeEmpty;

    final qrRepaintKey = useMemoized(GlobalKey.new);

    final shareQrAsImage = useCallback(
      () => shareWidgetAsImage(qrRepaintKey),
      [qrRepaintKey],
    );

    final showShareSheet = useCallback(() {
      final systemOverlayColor = ref.read(systemOverlayColorProvider(context));
      systemOverlayColor.modalColor(colors);

      AquaBottomSheet.show(
        context,
        colors: colors,
        topBorderRadius: 8,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 21),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaText.subtitleSemiBold(text: context.loc.share),
              const SizedBox(height: 24),
              AquaListItem(
                title: context.loc.receiveAssetScreenCopyAddressOptionShare,
                onTap: () {
                  Share.share(
                    result.deposit.qrCopyPaste,
                    sharePositionOrigin: context.sharePositionOrigin,
                  );
                  context.pop();
                },
                iconTrailing: AquaIcon.chevronForward(
                  color: colors.textSecondary,
                  size: 18,
                ),
                iconLeading: AquaIcon.qrIcon(color: colors.textSecondary),
              ),
              AquaListItem(
                title: context.loc.receiveAssetScreenCopyAddressOptionImage,
                onTap: () {
                  shareQrAsImage().catchError((e) {
                    if (context.mounted) {
                      context.showErrorSnackbar(
                        '${context.loc.failedToShareQrImage}: $e',
                      );
                    }
                  });
                  context.pop();
                },
                iconTrailing: AquaIcon.chevronForward(
                  color: colors.textSecondary,
                  size: 18,
                ),
                iconLeading: AquaIcon.image(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ).then((_) => systemOverlayColor.themeBased());
    }, [result.deposit.qrCopyPaste, shareQrAsImage]);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AquaText.body2Medium(
                  text: context.loc.depixDepositQrSubtitle,
                  color: colors.textTertiary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                AquaCard.glass(
                  width: double.maxFinite,
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      context.copyToClipboard(result.deposit.qrCopyPaste),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      DepixPixQrView(
                        payload: result.deposit.qrCopyPaste,
                        repaintKey: qrRepaintKey,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 36),
                        child: AquaText.body2(
                          text: result.deposit.qrCopyPaste,
                          textAlign: TextAlign.center,
                          color: context.aquaColors.textPrimary,
                          maxLines: 10,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                AquaCard.glass(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: AquaListItem(
                    colors: colors,
                    title: context.loc.amount,
                    subtitle: amountFormatted,
                    iconLeading:
                        AquaIcon.infoCircle(color: colors.textSecondary),
                  ),
                ),
                const SizedBox(height: 8),
                AquaCard.glass(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(8),
                  child: AquaListItem(
                    colors: colors,
                    title: context.loc.depixDepositEulenFee,
                    titleTrailing: feeFormatted,
                    titleTrailingColor: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: _BottomNavButton(
                  title: context.loc.share,
                  icon: AquaIcon.share(color: colors.textSecondary),
                  onTap: showShareSheet,
                ),
              ),
              Expanded(
                child: _BottomNavButton(
                  title: context.loc.copyAddress,
                  icon: AquaIcon.copy(color: colors.textSecondary),
                  onTap: () =>
                      context.copyToClipboard(result.deposit.qrCopyPaste),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }
}

class _DepixDepositQrSkeleton extends StatelessWidget {
  const _DepixDepositQrSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.aquaColors;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AquaText.body2Medium(
                  text: context.loc.depixDepositQrSubtitle,
                  color: colors.textTertiary,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Skeletonizer(
                  enabled: true,
                  child: AquaCard.glass(
                    width: double.maxFinite,
                    elevation: 8,
                    borderRadius: BorderRadius.circular(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 24),
                        Skeleton.shade(
                          child: Container(
                            width: 244,
                            height: 244,
                            decoration: BoxDecoration(
                              color: colors.surfaceTertiary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: AquaText.body2(
                            text: 'lorem ipsum dolor sit amet lorem ipsum',
                            textAlign: TextAlign.center,
                            color: colors.textPrimary,
                            maxLines: 10,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 61),
      ],
    );
  }
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final AquaIcon icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          color: Colors.transparent,
          padding: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 4),
              AquaText.caption2SemiBold(text: title),
            ],
          ),
        ),
      ),
    );
  }
}
