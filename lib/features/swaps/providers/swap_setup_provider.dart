import 'package:coin_cz/features/swaps/swaps.dart';
import 'package:coin_cz/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SwapSetupNotifier
    extends AutoDisposeFamilyAsyncNotifier<SwapSetupState, SwapArgs> {
  late final SwapService _service;
  late final SwapPair _pair;

  final _logger = CustomLogger(FeatureFlag.swap);

  @override
  Future<SwapSetupState> build(SwapArgs arg) async {
    try {
      _pair = arg.pair;

      // if serviceProvider wasn't passed, then resolve automatically
      final serviceProvider =
          arg.serviceProvider ?? ref.watch(swapServiceResolverProvider(_pair));

      if (serviceProvider == null) {
        throw SwapServiceGeneralException(
            'No swap service available for this pair');
      }

      // access service directly from registry
      final registry = ref.watch(swapServicesRegistryProvider);
      if (registry[serviceProvider] == null) {
        throw SwapServiceGeneralException(
            'Service not found: ${serviceProvider.displayName}');
      }
      _service = registry[serviceProvider]!;

      _logger
          .debug('SwapSetupNotifier initialized for ${_service.runtimeType}');
      return const SwapSetupState();
    } catch (e, _) {
      _logger.error('Error initializing SwapSetupNotifier: $e');
      throw SwapServiceGeneralException(e.toString());
    }
  }

  Future<void> checkPermissions() async {
    state = await AsyncValue.guard(() async {
      final permissionsChecked = await _service.checkPermissions();
      return state.value!.copyWith(permissionsChecked: permissionsChecked);
    });
  }

  Future<void> fetchAvailableAssets() async {
    state = await AsyncValue.guard(() async {
      final assets = await _service.getAvailableAssets();
      return state.value!.copyWith(availableAssets: assets);
    });
  }

  Future<void> getAvailablePairs() async {
    state = await AsyncValue.guard(() async {
      final pairs = await _service.getAvailablePairs(
        from: _pair.from,
        to: _pair.to,
      );
      return state.value!.copyWith(availablePairs: pairs);
    });
  }
}

final swapSetupProvider = AutoDisposeAsyncNotifierProviderFamily<
    SwapSetupNotifier, SwapSetupState, SwapArgs>(
  SwapSetupNotifier.new,
);
