import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'swap_status_provider.freezed.dart';

@freezed
class SwapStatusParams with _$SwapStatusParams {
  const factory SwapStatusParams({
    required String orderId,
    required SwapServiceSource serviceType,
  }) = _SwapStatusParams;

  factory SwapStatusParams.fromOrder(SwapOrderDbModel order) =>
      SwapStatusParams(
        orderId: order.orderId,
        serviceType: order.serviceType,
      );
}

class SwapStatusCheckNotifier extends AutoDisposeFamilyAsyncNotifier<
    SwapStatusCheckState, SwapStatusParams> {
  late final SwapService _service;
  final _logger = CustomLogger(FeatureFlag.swap);

  @override
  Future<SwapStatusCheckState> build(SwapStatusParams arg) async {
    try {
      // access service directly from registry
      final registry = ref.watch(swapServicesRegistryProvider);
      if (registry[arg.serviceType] == null) {
        throw SwapServiceGeneralException(
            'Service not found: ${arg.serviceType.displayName}');
      }
      _service = registry[arg.serviceType]!;

      _logger.debug(
          'SwapStatusCheckNotifier initialized for ${_service.runtimeType}');

      await for (final status in _service.getOrderStatus(arg.orderId)) {
        await _service.updateOrderStatus(arg.orderId, status);
        state = AsyncData(SwapStatusCheckState(
          orderId: arg.orderId,
          orderStatus: status,
        ));
      }

      return state.value ?? const SwapStatusCheckState();
    } catch (e, _) {
      _logger.error('Error in SwapStatusCheckNotifier: $e');
      throw SwapServiceOrderStatusException(e.toString());
    }
  }
}

final swapStatusProvider = AutoDisposeAsyncNotifierProviderFamily<
    SwapStatusCheckNotifier, SwapStatusCheckState, SwapStatusParams>(
  SwapStatusCheckNotifier.new,
);
