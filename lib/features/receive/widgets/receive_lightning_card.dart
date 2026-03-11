import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/models/lightning_success_arguments.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
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

  const ReceiveLightningCard({super.key, required this.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boltzUiState = ref.watch(boltzReverseSwapProvider);
    final reverseFees = ref.watch(boltzReverseFeesProvider).valueOrNull;
    final formatter = ref.read(formatProvider);
    final unitsProvider = ref.read(displayUnitsProvider);
    final currentUnit = unitsProvider.currentDisplayUnit;
    final currencyUnit = currentUnit.value.toLowerCase();

    final minAmountFormatted = formatter.formatAssetAmount(
      amount: reverseFees?.lbtcLimits.minimal.toInt() ?? 0,
      asset: args.asset,
      displayUnitOverride: currentUnit,
    );
    final maxAmountFormatted = formatter.formatAssetAmount(
      amount: reverseFees?.lbtcLimits.maximal.toInt() ?? 0,
      asset: args.asset,
      displayUnitOverride: currentUnit,
    );
    final minLimit =
        reverseFees != null ? '$minAmountFormatted $currencyUnit' : null;
    final maxLimit =
        reverseFees != null ? '$maxAmountFormatted $currencyUnit' : null;
    final boltzOrder = useMemoized(
      () => boltzUiState.mapOrNull(qrCode: (s) => s.swap),
      [boltzUiState],
    );

    if (boltzOrder != null) {
      // listen for boltz claim to show lightning success screen
      ref.listen(boltzSwapStatusProvider(boltzOrder.id), (_, event) async {
        final status = event.value?.status;
        logger.debug('[Receive] Boltz Swap Status: $status');
        if (status?.isSuccess == true) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.pushReplacement(
              AssetTransactionSuccessScreen.routeName,
              extra: LightningSuccessArguments(
                      satoshiAmount: boltzOrder.outAmount.toInt(),
                      boltzOrderId: boltzOrder.id)
                  .toTransactionSucessArguments(),
            );
          });
        }
      });

      // listen for boltz-to-boltz receives to show lightning success screen
      ref.listen<AsyncValue<List<String>?>>(
          boltzToBoltzReceiveProvider(boltzOrder.id), (_, event) {
        event.whenData((txs) {
          if (txs != null && txs.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.pushReplacement(
                AssetTransactionSuccessScreen.routeName,
                extra: LightningSuccessArguments(
                        satoshiAmount: boltzOrder.outAmount.toInt(),
                        boltzOrderId: boltzOrder.id)
                    .toTransactionSucessArguments(),
              );
            });
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
              minLimit: minLimit,
              maxLimit: maxLimit,
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
        qrCode: (swap) => _LightningReceiveContent(args: args),
        orElse: () => const _LoadingContent(),
      ),
    );
  }
}

class _LightningReceiveContent extends ConsumerWidget {
  const _LightningReceiveContent({required this.args});

  final ReceiveAmountArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvoked: (_) {
        // Reset to enter amount state
        ref.invalidate(boltzReverseSwapProvider);
      },
      child: Column(
        children: [
          //ANCHOR - Lightning Swap Warning
          AquaText.body2Medium(
            text: context.loc.assetsReceiveLightningQRSubtitle,
            color: context.aquaColors.textTertiary,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          //ANCHOR - Lightning QR and controls
          ReceiveAddressContent(asset: args.asset),
        ],
      ),
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
