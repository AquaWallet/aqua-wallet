import 'dart:async';

import 'package:aqua/logger.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final boltzInitProvider =
    AsyncNotifierProvider<BoltzInitProvider, void>(BoltzInitProvider.new);

class BoltzInitProvider extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    state = const AsyncValue.loading();
    try {
      await LibBoltz.init();
      logger.debug('[Boltz] BoltzCore initialized successfully.');

      state = const AsyncValue.data(null);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}
