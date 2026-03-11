import 'dart:async';

import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/shared/shared.dart';

final boltzProofOfPaymentProvider = AutoDisposeAsyncNotifierProviderFamily<
    BoltzProofOfPaymentNotifier,
    String?,
    String?>(BoltzProofOfPaymentNotifier.new);

class BoltzProofOfPaymentNotifier
    extends AutoDisposeFamilyAsyncNotifier<String?, String?> {
  @override
  FutureOr<String?> build(String? arg) async {
    final boltzOrderId = arg;
    if (boltzOrderId == null) return null;
    final swap = await ref
        .read(boltzStorageProvider.notifier)
        .getLbtcLnV2SwapById(boltzOrderId);
    final swapStatus =
        (await ref.read(boltzSwapStatusProvider(boltzOrderId).future)).status;

    if (swap == null || swap.invoice.isEmpty || !swapStatus.isSuccess) {
      return null;
    }

    final invoice = swap.invoice;
    final client = ref.read(dioProvider);
    final baseUri = ref.read(boltzEnvConfigProvider).apiUrl;
    final uri = '$baseUri/swap/submarine/${swap.id}/preimage';
    final response = await client.get(uri);
    final preimage = response.data['preimage'] as String?;
    if (preimage == null || preimage.isEmpty) {
      return null;
    }
    return '$proofOfPaymentBaseUrl?invoice=$invoice&preimage=$preimage';
  }
}
