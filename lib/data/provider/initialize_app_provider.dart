import 'dart:async';

import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/gdk.dart';
import 'package:coin_cz/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

final _logger = CustomLogger(FeatureFlag.initAppProvider);

final initAppProvider =
    AsyncNotifierProvider<InitAppProvider, void>(InitAppProvider.new);

class InitAppProvider extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    state = const AsyncValue.loading();
    _logger.debug('state: loading');
    const int splashScreenMinDurationInMs =
        1000; // 1 second artificial delay to make sure splash screen is show with logo is shown
    final startTime = DateTime.now();
    try {
      final dir = await getApplicationSupportDirectory();

      final config = GdkConfig(
          dataDir: dir.absolute.path, logLevel: GdkConfigLogLevelEnum.info);
      final libGdk = LibGdk();
      await libGdk.initGdk(config);

      await ref.read(liquidProvider).init();

      await ref.read(bitcoinProvider).init();

      /**
      * App is initialized.
      * Connect to remote network services.
      */
      ref.read(aquaConnectionProvider.notifier).connect();

      _logger.debug('Initialized bitcoin and liquid backend');

      // Splash Screen Delay
      // TODO: Handle this in a splash screen provider in the future
      final splashScreenRemainingDurationInMs = splashScreenMinDurationInMs -
          DateTime.now().difference(startTime).inMilliseconds;
      if (splashScreenRemainingDurationInMs > 0) {
        await Future.delayed(
            Duration(milliseconds: splashScreenRemainingDurationInMs));
      }

      state = const AsyncValue.data(null);
    } catch (error) {
      _logger.error('Error initializing app: $error');
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}
