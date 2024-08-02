import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:aqua/logger.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

final boltzInitProvider =
    AsyncNotifierProvider<BoltzInitProvider, void>(BoltzInitProvider.new);

class BoltzInitProvider extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    state = const AsyncValue.loading();
    try {
      final externalLibrary = Platform.isIOS
          ? ExternalLibrary.open(
              '${NSBundleHelper.mainBundlePath}/Frameworks/boltz_dart.framework/boltz_dart')
          : null;
      await BoltzCore.init(externalLibrary: externalLibrary);
      logger.d('[Boltz] BoltzCore initialized successfully.');

      state = const AsyncValue.data(null);
    } catch (error) {
      state = AsyncValue.error(error, StackTrace.current);
    }
  }
}

final DynamicLibrary _objcLib = DynamicLibrary.process();

class NSBundleHelper {
  static final Pointer<Utf8> Function() _getMainBundlePath = _objcLib
      .lookup<NativeFunction<Pointer<Utf8> Function()>>('getMainBundlePath')
      .asFunction();

  static String get mainBundlePath => _getMainBundlePath().toDartString();
}
