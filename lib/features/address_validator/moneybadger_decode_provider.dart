import 'dart:async';

import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

/// Decodes a QR string via the Moneybadger backend.
/// Returns the lightning address on success, null if the input is not a
/// Moneybadger QR or the backend is unavailable.
final moneybadgerDecodeProvider =
    AsyncNotifierProvider<MoneybadgerDecodeNotifier, String?>(
        MoneybadgerDecodeNotifier.new);

class MoneybadgerDecodeNotifier extends AsyncNotifier<String?> {
  @override
  FutureOr<String?> build() async => null;

  Future<String?> decode(String input) async {
    final isTestnet = ref.read(envProvider) != Env.mainnet;
    try {
      final service = await ref.read(jan3ApiServiceProvider.future);
      final response = await service.decodeMoneybadger(
        MoneybadgerDecodeRequest(qrData: input, isTestnet: isTestnet),
      );
      final address = response.body?.lightningAddress;
      return address?.isNotEmpty == true ? address : null;
    } catch (e) {
      logger.warning('[QR] Moneybadger decode failed: $e');
      // Backend unavailable or unrecognised QR — caller continues.
      return null;
    }
  }
}
