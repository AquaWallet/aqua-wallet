import 'dart:async';

import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/lightning_address/services/services.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';

final lnAddressEditInputProvider = AsyncNotifierProvider.autoDispose<
    LnAddressEditFormNotifier,
    LnAddressEditFormState>(LnAddressEditFormNotifier.new);

class LnAddressEditFormNotifier
    extends AutoDisposeAsyncNotifier<LnAddressEditFormState> {
  static const _availabilityDebounceDuration = Duration(milliseconds: 400);

  Timer? _availabilityDebounce;

  @override
  Future<LnAddressEditFormState> build() async {
    ref.onDispose(() => _availabilityDebounce?.cancel());

    final currentUsername =
        ref.watch(lightningAddressProvider)?.address.split('@').first ?? '';

    return LnAddressEditFormState(
      currentUsername: currentUsername,
      inputUsername: currentUsername,
    );
  }

  Future<void> setUsername(String value) async {
    final current = state.valueOrNull;
    if (current == null) return;

    _availabilityDebounce?.cancel();

    state = AsyncData(
      current.copyWith(inputUsername: value, isAvailable: null),
    );

    if (value.isEmpty || value == current.currentUsername) {
      return;
    }

    _availabilityDebounce = Timer(_availabilityDebounceDuration, () {
      _availabilityDebounce = null;
      unawaited(_fetchUsernameAvailability(value));
    });
  }

  Future<void> _fetchUsernameAvailability(String value) async {
    try {
      final api = ref.read(jan3ApiLightningAddressesProvider);
      final response = await api.isLnUsernameAvailable(value);

      final latest = state.valueOrNull;
      if (latest?.inputUsername == value) {
        state = AsyncData(
          latest!.copyWith(isAvailable: response.body!.isAvailable),
        );
      }
    } catch (e, st) {
      final latest = state.valueOrNull;
      if (latest?.inputUsername == value) {
        state = AsyncError(e, st);
      }
    }
  }

  void prefillUsername(String username) {
    _availabilityDebounce?.cancel();
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(inputUsername: username, isAvailable: true),
    );
  }

  void setSelectedAsset(Asset asset) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(current.copyWith(selectedAsset: asset));
  }
}
