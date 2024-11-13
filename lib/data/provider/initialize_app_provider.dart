import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/gdk.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final initAppProvider =
    AsyncNotifierProvider<InitAppProvider, void>(InitAppProvider.new);

class InitAppProvider extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    state = const AsyncValue.loading();
    const int splashScreenMinDurationInMs = 2100; // 2.1 seconds
    final startTime = DateTime.now();
    try {
      final dir = await getApplicationSupportDirectory();

      final config = GdkConfig(
          dataDir: dir.absolute.path, logLevel: GdkConfigLogLevelEnum.info);
      final libGdk = LibGdk();
      await libGdk.initGdk(config);

      await ref.read(liquidProvider).init();

      await ref.read(bitcoinProvider).init();

      logger.d('[InitAppProvider] Finished backends initialization');

      // Splash Screen Delay
      // TODO: Handle this in a splash screen provider in the future
      final splashScreenRemainingDurationInMs = splashScreenMinDurationInMs -
          DateTime.now().difference(startTime).inMilliseconds;
      if (splashScreenRemainingDurationInMs > 0) {
        await Future.delayed(
            Duration(milliseconds: splashScreenRemainingDurationInMs));
      }

      /**
      * App is initialized.
      * Connect to remote network services.
      */
      ref.read(aquaConnectionProvider.notifier).connect();

      state = const AsyncValue.data(null);
    } catch (error) {
      logger.e('[InitAppProvider] Error initializing app: $error');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}
