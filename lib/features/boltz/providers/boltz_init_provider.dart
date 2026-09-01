import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = CustomLogger(FeatureFlag.boltz);

final boltzInitProvider =
    AsyncNotifierProvider<BoltzInitProvider, void>(BoltzInitProvider.new);

class BoltzInitProvider extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    try {
      await LibBoltz.init();
      _logger.debug('[Boltz] BoltzCore initialized successfully.');
    } catch (error, stackTrace) {
      _logger.error('[Boltz] BoltzCore init failed', error, stackTrace);
      rethrow;
    }
  }
}
