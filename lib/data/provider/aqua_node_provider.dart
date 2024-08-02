import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/provider_extensions.dart';

import 'package:freezed_annotation/freezed_annotation.dart';
part 'aqua_node_provider.freezed.dart';
part 'aqua_node_provider.g.dart';

@freezed
class NodeStatusResponse with _$NodeStatusResponse {
  factory NodeStatusResponse(
          {@JsonKey(name: 'blockHeight') required int blockHeight}) =
      _NodeStatusResponse;

  factory NodeStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$NodeStatusResponseFromJson(json);
}

final aquaNodeStatusProvider =
    FutureProvider.autoDispose<NodeStatusResponse>((ref) async {
  try {
    final response = await ref
        .read(dioProvider)
        .get('https://mempool.aquawallet.io/api/liquid/status');
    final json = response.data as Map<String, dynamic>;
    final status = NodeStatusResponse.fromJson(json);
    logger.d("[aquaNodeStatus] status block height: ${status.blockHeight}");
    ref.refreshAfter(const Duration(seconds: 30));
    return status;
  } catch (e) {
    logger.e('[aquaNodeStatus] status request failed:', e);
    rethrow;
  }
});

final isAquaNodeSyncedProvider = StateProvider.autoDispose<bool?>((ref) {
  final status = ref.watch(aquaNodeStatusProvider).asData?.value;
  final connStatus = ref.watch(connectionStatusProvider).asData?.value;

  if (status == null ||
      connStatus == null ||
      connStatus.initialized == false ||
      connStatus.lastLiquidBlock == null) {
    return null;
  }

  // node is considered out-of-sync if it's 3 or more blocks behind
  return !(status.blockHeight <= connStatus.lastLiquidBlock! - 3);
});
