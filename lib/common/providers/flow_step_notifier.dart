import 'package:aqua/common/data_structure/data_stack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stack-backed step controller for multi-step flows: [setStep], [goBack], [reset].
///
/// Use this directly when you need step-flow logic outside of a Riverpod
/// notifier, or embed it via [FlowStepMixin] for notifier-based flows.
///
/// Initial [current] is null until the first [setStep]. [reset] restores
/// [rootStep] and clears history down to that step.
class FlowStepController<T extends Object> {
  FlowStepController({required T rootStep}) : _rootStep = rootStep;

  final T _rootStep;
  final _history = DataStack<T>();
  T? _current;

  T? get current => _current;

  void setStep(T step) {
    if (_history.isEmpty || _history.peek != step) {
      _history.push(step);
    }
    _current = step;
  }

  T? goBack({T? to}) {
    if (_history.length <= 1) return null;

    if (to != null) {
      if (!_history.contains(to)) return null;
      _history.popUntil(to);
    } else {
      _history.pop();
    }

    return _current = _history.peek;
  }

  void reset() {
    _history
      ..clear()
      ..push(_rootStep);
    _current = _rootStep;
  }
}

/// Mixin for [AutoDisposeNotifier] subclasses that need stack-backed step flow.
///
/// Implement [rootStep] to define the initial step. The mixin exposes
/// [setStep], [goBack], and [reset] — each updates [state] automatically.
///
/// ```dart
/// class MyNotifier extends AutoDisposeNotifier<MyStep?>
///     with FlowStepMixin<MyStep> {
///   @override
///   MyStep get rootStep => MyStep.first;
///
///   @override
///   MyStep? build() => null;
/// }
/// ```
mixin FlowStepMixin<T extends Object> on AutoDisposeNotifier<T?> {
  T get rootStep;

  late final _flow = FlowStepController<T>(rootStep: rootStep);

  void setStep(T step) {
    _flow.setStep(step);
    state = _flow.current;
  }

  T? goBack({T? to}) {
    final nextCurrent = _flow.goBack(to: to);
    state = _flow.current;
    return nextCurrent;
  }

  void reset() {
    _flow.reset();
    state = _flow.current;
  }
}
