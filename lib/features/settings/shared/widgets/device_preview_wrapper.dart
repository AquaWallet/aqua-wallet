import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/main.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AppWithDevicePreviewWrapper extends HookWidget {
  const AppWithDevicePreviewWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final needsDevicePreview = useMemoized(() {
      return const String.fromEnvironment('DEVICE_PREVIEW') == 'true';
    });
    if (needsDevicePreview) {
      return DevicePreview(
        enabled: !kReleaseMode,
        builder: (_) => const AquaApp(),
      );
    } else {
      return const AquaApp();
    }
  }
}
