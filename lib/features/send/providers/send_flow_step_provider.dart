import 'package:aqua/common/data_structure/data_stack.dart';
import 'package:aqua/features/shared/shared.dart' hide Stack;

enum SendFlowStep {
  address,
  network,
  amount,
  review,
}

/// Provider to manage the current step and navigation history in the send flow.
/// Tracks visited steps to enable proper back navigation.
final sendFlowStepProvider =
    StateNotifierProvider.autoDispose<SendFlowStepNotifier, SendFlowStep?>(
        (_) => SendFlowStepNotifier());

class SendFlowStepNotifier extends StateNotifier<SendFlowStep?> {
  SendFlowStepNotifier() : super(null);

  final _history = DataStack<SendFlowStep>();

  void setStep(SendFlowStep step) {
    if (_history.isEmpty || _history.peek != step) {
      _history.push(step);
    }
    state = step;
  }

  SendFlowStep? goBack({SendFlowStep? to}) {
    if (_history.length <= 1) return null;

    if (to != null) {
      if (!_history.contains(to)) return null;
      _history.popUntil(to);
    } else {
      _history.pop();
    }

    state = _history.peek;
    return state;
  }

  void reset() {
    _history
      ..clear()
      ..push(SendFlowStep.address);
    state = SendFlowStep.address;
  }
}
