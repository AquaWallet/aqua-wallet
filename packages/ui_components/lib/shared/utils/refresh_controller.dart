import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

typedef AsyncRefreshCallback = Future<void> Function();

/// Controller that manages refresh state independently from UI components.
/// This allows decoupling the pull-to-refresh gesture detection from
/// the loading indicator display.
class AquaRefreshController extends ChangeNotifier {
  bool _isRefreshing = false;
  AsyncRefreshCallback? _onRefresh;

  bool get isRefreshing => _isRefreshing;

  void setOnRefresh(AsyncRefreshCallback? callback) {
    _onRefresh = callback;
  }

  Future<void> refresh() async {
    if (_isRefreshing || _onRefresh == null) return;

    _isRefreshing = true;
    notifyListeners();

    try {
      await _onRefresh!();
    } finally {
      // Keep refreshing state active until explicitly stopped
      // This allows the UI to control when to stop the indicator
    }
  }

  void stopRefresh() {
    if (!_isRefreshing) return;

    _isRefreshing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _onRefresh = null;
    super.dispose();
  }
}

/// Hook that provides an AquaRefreshController instance
AquaRefreshController useRefreshController() {
  return use(const _RefreshControllerHook());
}

class _RefreshControllerHook extends Hook<AquaRefreshController> {
  const _RefreshControllerHook();

  @override
  _RefreshControllerHookState createState() => _RefreshControllerHookState();
}

class _RefreshControllerHookState
    extends HookState<AquaRefreshController, _RefreshControllerHook> {
  late final AquaRefreshController _controller;

  @override
  void initHook() {
    super.initHook();
    _controller = AquaRefreshController();
  }

  @override
  AquaRefreshController build(BuildContext context) => _controller;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  String get debugLabel => 'useRefreshController';
}
