import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:webview_flutter/webview_flutter.dart';

final _logger = CustomLogger(FeatureFlag.captcha);

typedef CaptchaArgs = ({bool isDarkMode, Duration timeout});

enum CaptchaPhase { initial, loading, ready, tokenReceived, timedOut }

const String captchaBaseUrl = 'https://ankara.aquabtc.com/api/v1/auth/captcha/';

class CaptchaState {
  final CaptchaPhase phase;
  final WebViewController? controller;
  final String? token;

  const CaptchaState({
    required this.phase,
    this.controller,
    this.token,
  });

  const CaptchaState.initial() : this(phase: CaptchaPhase.initial);
  const CaptchaState.loading() : this(phase: CaptchaPhase.loading);
  const CaptchaState.timedOut() : this(phase: CaptchaPhase.timedOut);
  const CaptchaState.ready(WebViewController controller)
      : this(phase: CaptchaPhase.ready, controller: controller);
  const CaptchaState.token(
      {required String token, required WebViewController controller})
      : this(
            phase: CaptchaPhase.tokenReceived,
            token: token,
            controller: controller);
}

final captchaProvider = AutoDisposeAsyncNotifierProviderFamily<CaptchaNotifier,
    CaptchaState, CaptchaArgs>(CaptchaNotifier.new);

class CaptchaNotifier
    extends AutoDisposeFamilyAsyncNotifier<CaptchaState, CaptchaArgs> {
  Timer? _timeoutTimer;
  bool _timeoutCancelled = false;

  @override
  Future<CaptchaState> build(CaptchaArgs arg) async {
    state = const AsyncValue.loading();

    ref.onDispose(() {
      _timeoutTimer?.cancel();
    });

    try {
      final controller = WebViewController();
      controller
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..enableZoom(false)
        ..addJavaScriptChannel(
          'TokenChannel',
          onMessageReceived: (message) {
            final token = message.message;
            if (!_timeoutCancelled) {
              _timeoutCancelled = true;
              _timeoutTimer?.cancel();
            }
            state = AsyncData(
                CaptchaState.token(token: token, controller: controller));
          },
        )
        ..addJavaScriptChannel(
          'ErrorChannel',
          onMessageReceived: (message) {
            if (!_timeoutCancelled) {
              _timeoutCancelled = true;
              _timeoutTimer?.cancel();
            }
            state = AsyncData(
                CaptchaState.token(token: '', controller: controller));
          },
        );
      controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            _logger.debug('Page started loading: $url');
          },
          onPageFinished: (url) {
            _logger.debug('Page finished loading: $url');
            state = state.whenData((_) => CaptchaState.ready(controller));
          },
          onWebResourceError: (error) {
            if (!_timeoutCancelled) {
              _timeoutCancelled = true;
              _timeoutTimer?.cancel();
            }
            final err = Exception(error.description);
            state = AsyncValue.error(err, StackTrace.current);
          },
        ),
      );

      try {
        await controller.loadRequest(Uri.parse(arg.isDarkMode
            ? '$captchaBaseUrl/dark/'
            : '$captchaBaseUrl/light/'));
        _logger.debug('HTML loaded successfully with baseUrl');
      } catch (e, stack) {
        if (_timeoutCancelled) rethrow;
        _timeoutCancelled = true;
        _timeoutTimer?.cancel();
        state = AsyncValue.error(e, stack);
        rethrow;
      }

      _timeoutTimer = Timer(arg.timeout, () {
        if (_timeoutCancelled) return;
        _timeoutCancelled = true;
        _logger.warning(
            'Token request timed out after ${arg.timeout.inSeconds} seconds');
        state = const AsyncData(CaptchaState.timedOut());
      });

      return const CaptchaState.loading();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}
