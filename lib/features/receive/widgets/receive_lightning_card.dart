import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/feature_flags/providers/setup_config_provider.dart';
import 'package:aqua/features/lightning/models/lightning_success_arguments.dart';
import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class ReceiveLightningCard extends HookConsumerWidget {
  final ReceiveAmountArguments args;

  const ReceiveLightningCard({
    super.key,
    required this.args,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupAsync = ref.watch(setupConfigProvider);
    final lnAddressState = ref.watch(lightningAddressProvider);
    final isInvoiceMode = ref.watch(lnReceiveModeProvider);

    final showLnAddress = lnAddressState.isActive;

    if (showLnAddress && !isInvoiceMode) {
      return Expanded(
        child: _LightningAddressReceiveContent(
          lnAddress: lnAddressState!.address,
          asset: args.asset,
        ),
      );
    }

    // Wait for remote flags before starting the Boltz flow to avoid a race
    // condition where Boltz initializes and then gets interrupted mid-load when
    // the flag arrives and switches the UI to the LN address flow.
    if (setupAsync.isLoading) {
      return const Expanded(child: _LoadingContent());
    }

    return _BoltzInvoiceFlow(
      args: args,
      hasLnAddress: lnAddressState.isRegistered,
    );
  }
}

/// Existing Boltz invoice flow extracted into its own widget
class _BoltzInvoiceFlow extends HookConsumerWidget {
  final ReceiveAmountArguments args;
  final bool hasLnAddress;

  const _BoltzInvoiceFlow({
    required this.args,
    this.hasLnAddress = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boltzUiState = ref.watch(boltzReverseSwapProvider);
    final reverseFees = ref.watch(boltzReverseFeesProvider).valueOrNull;
    final minLimitSats = reverseFees?.lbtcLimits.minimal.toInt();
    final maxLimitSats = reverseFees?.lbtcLimits.maximal.toInt();
    final boltzOrder = useMemoized(
      () => boltzUiState.mapOrNull(qrCode: (s) => s.swap),
      [boltzUiState],
    );

    if (boltzOrder != null) {
      void navigateToSuccess() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.pushReplacement(
            AssetTransactionSuccessScreen.routeName,
            extra: LightningSuccessArguments(
              satoshiAmount: boltzOrder.outAmount.toInt(),
              boltzOrderId: boltzOrder.id,
            ).toTransactionSucessArguments(),
          );
        });
      }

      ref.listen(boltzSwapStatusProvider(boltzOrder.id), (_, event) {
        final status = event.value?.status;
        logger.debug('[Receive] Boltz Swap Status: $status');
        if (status?.isSuccess == true) {
          navigateToSuccess();
        }
      });

      // listen for boltz-to-boltz receives to show lightning success screen
      ref.listen<AsyncValue<List<String>?>>(
          boltzToBoltzReceiveProvider(boltzOrder.id), (_, event) {
        event.whenData((txs) {
          if (txs != null && txs.isNotEmpty) {
            navigateToSuccess();
          }
        });
      });
    }

    useEffect(() {
      if (boltzUiState.isAmountEntry) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted || reverseFees == null) return;
          context.push(
            ReceiveAmountScreen.routeName,
            extra: ReceiveAmountArguments(
              asset: args.asset,
              minLimitSats: minLimitSats,
              maxLimitSats: maxLimitSats,
              onContinuePressed: () {
                final amount = ref.read(receiveAssetAmountProvider);
                ref
                    .read(boltzReverseSwapProvider.notifier)
                    .generateInvoice(Decimal.parse(amount ?? '0'), context.loc);
              },
              isAmountCompulsory: true,
            ),
          );
        });
      }
      return null;
    }, [boltzUiState.isAmountEntry, reverseFees]);

    return Expanded(
      child: boltzUiState.maybeWhen(
        qrCode: (swap) => _LightningReceiveContent(
          args: args,
          hasLnAddress: hasLnAddress,
        ),
        orElse: () => const _LoadingContent(),
      ),
    );
  }
}

//ANCHOR - Lightning Address Receive Content
class _LightningAddressReceiveContent extends StatelessWidget {
  const _LightningAddressReceiveContent({
    required this.lnAddress,
    required this.asset,
  });

  final String lnAddress;
  final Asset asset;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AquaText.body2Medium(
          text: context.loc.assetsReceiveLightningQRSubtitle,
          color: context.aquaColors.textTertiary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              AquaCard.glass(
                width: double.maxFinite,
                elevation: 8,
                borderRadius: BorderRadius.circular(8),
                onTap: () => context.copyToClipboard(lnAddress),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),
                    ReceiveAssetQrCode(
                      assetAddress: lnAddress,
                      asset: asset,
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 38),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: AquaText.body2SemiBold(
                              text: lnAddress,
                              color: context.aquaColors.accentBrand,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => AquaBottomSheet.show(
                              context,
                              colors: context.aquaColors,
                              content: const LnAddressEditBottomSheetContent(),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(width: 6),
                                AquaIcon.edit(
                                  size: 16,
                                  color: context.aquaColors.accentBrand,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const LnReceiveModeSwitcher(),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

//ANCHOR - Lightning Invoice Receive Content (existing Boltz flow)
class _LightningReceiveContent extends ConsumerWidget {
  const _LightningReceiveContent({
    required this.args,
    this.hasLnAddress = false,
  });

  final ReceiveAmountArguments args;
  final bool hasLnAddress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reverseFees = ref.watch(boltzReverseFeesProvider).valueOrNull;
    final minLimitSats = reverseFees?.lbtcLimits.minimal.toInt();
    final maxLimitSats = reverseFees?.lbtcLimits.maximal.toInt();
    final bip21Amount =
        ref.watch(receiveAssetAmountForBip21Provider(args.asset));
    final formatter = ref.watch(formatProvider);
    final displayUnits = ref.watch(displayUnitsProvider).currentDisplayUnit;
    final amountSats = bip21Amount != null && bip21Amount.isNotEmpty
        ? (int.tryParse(bip21Amount) ?? 0)
        : 0;
    final amountSubtitle = amountSats > 0
        ? '${formatter.formatAssetAmount(amount: amountSats, asset: args.asset, displayUnitOverride: displayUnits)} ${displayUnits.value.toLowerCase()}'
        : '--';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AquaText.body2Medium(
          text: context.loc.assetsReceiveLightningQRSubtitle,
          color: context.aquaColors.textTertiary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ReceiveAddressContent(
          asset: args.asset,
          hideAmountRow: true,
        ),
        AquaCard.glass(
          elevation: 8,
          borderRadius: BorderRadius.circular(8),
          child: AquaListItem(
            onTap: () => context.push(
              ReceiveAmountScreen.routeName,
              extra: ReceiveAmountArguments(
                asset: args.asset,
                minLimitSats: minLimitSats,
                maxLimitSats: maxLimitSats,
                onContinuePressed: reverseFees != null
                    ? () {
                        final amount = ref.read(receiveAssetAmountProvider);
                        ref
                            .read(boltzReverseSwapProvider.notifier)
                            .generateInvoice(
                                Decimal.parse(amount ?? '0'), context.loc);
                      }
                    : null,
                isAmountCompulsory: true,
              ),
            ),
            colors: context.aquaColors,
            title: context.loc.amount,
            subtitle: amountSubtitle,
            iconLeading: AquaIcon.edit(
              color: context.aquaColors.textSecondary,
            ),
            iconTrailing: AquaIcon.chevronForward(
              size: 18,
              color: context.aquaColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LoadingContent extends HookConsumerWidget {
  const _LoadingContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Skeletonizer(
      enabled: true,
      child: Column(
        children: [
          const SizedBox(height: 24),
          //ANCHOR - Address QR Code
          AquaCard.glass(
            width: double.maxFinite,
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 14),
                //ANCHOR - Single Use Address with expiry

                const SizedBox(height: 16),
                Skeleton.shade(
                  child: Container(
                    width: kQrCardSize,
                    height: kQrCardSize,
                    decoration: BoxDecoration(
                      color: context.aquaColors.surfaceTertiary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'lorem ipsum dolor sit amet lorem ipsum sit',
                ),
                const Text(
                  'lorem ipsum dolor',
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
