import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter/material.dart';

void observeAppLifecycle(void Function(AppLifecycleState) onLifecycleChanged) {
  final observer = useMemoized(() => _AppLifecycleObserver(onLifecycleChanged));
  useEffect(() {
    WidgetsBinding.instance.addObserver(observer);
    return () => WidgetsBinding.instance.removeObserver(observer);
  }, [observer]);
}

class _AppLifecycleObserver with WidgetsBindingObserver {
  final void Function(AppLifecycleState) onLifecycleChanged;

  _AppLifecycleObserver(this.onLifecycleChanged);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    onLifecycleChanged(state);
  }
}
