import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/models/lightning_success_arguments.dart';
import 'package:aqua/features/lightning/pages/lightning_transaction_success_screen.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveLightningCard extends HookConsumerWidget {
  final Asset asset;

  const ReceiveLightningCard({super.key, required this.asset});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boltzUiState = ref.watch(boltzReverseSwapProvider);
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
              LightningTransactionSuccessScreen.routeName,
              extra: LightningSuccessArguments(
                  satoshiAmount: boltzOrder.outAmount,
                  type: LightningSuccessType.receive,
                  orderId: boltzOrder.id),
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
                LightningTransactionSuccessScreen.routeName,
                extra: LightningSuccessArguments(
                    satoshiAmount: boltzOrder.outAmount,
                    type: LightningSuccessType.receive,
                    orderId: boltzOrder.id),
              );
            });
          }
        });
      });
    }

    return boltzUiState.when(
      enterAmount: () => BoltzAmountEntryView(asset: asset),
      generatingInvoice: () => BoltzAmountEntryView(asset: asset),
      qrCode: (swap) => ReceiveAddressCard(
        asset: asset,
      ),
      success: (amountSats) => const SizedBox
          .shrink(), // success screen handled in boltzSwapStatusProvider listener
    );
  }
}
