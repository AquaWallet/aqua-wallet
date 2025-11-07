import 'package:aqua/features/account/providers/captcha_provider.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CaptchaWidget extends HookConsumerWidget {
  final Duration timeoutDuration;
  final ValueChanged<String?> onTokenReceived;

  const CaptchaWidget({
    super.key,
    this.timeoutDuration = const Duration(seconds: 30),
    required this.onTokenReceived,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final args = (isDarkMode: darkMode, timeout: timeoutDuration);
    useEffect(() {
      ref.invalidate(captchaProvider(args));
      onTokenReceived.call(null);
      return null;
    }, const []);
    final captchaAsync = ref.watch(captchaProvider(args));

    ref.listen(captchaProvider(args), (prev, next) {
      if (next.hasError) {
        onTokenReceived.call(null);
        return;
      }
      final data = next.asData?.value;
      if (data == null) return;
      switch (data.phase) {
        case CaptchaPhase.tokenReceived:
          onTokenReceived
              .call(data.token?.isNotEmpty == true ? data.token : '');
          break;
        case CaptchaPhase.timedOut:
          onTokenReceived.call(null);
          break;
        default:
          break;
      }
    });

    final controller = captchaAsync.when(
      data: (d) => (d.phase == CaptchaPhase.ready ||
              d.phase == CaptchaPhase.tokenReceived)
          ? d.controller
          : null,
      loading: () => null,
      error: (_, __) => null,
    );

    if (controller == null) return const SizedBox.shrink();

    return SizedBox(height: 70, child: WebViewWidget(controller: controller));
  }
}
