import 'package:aqua/common/providers/flow_step_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum DepixStep { depositsList, amountEntry, depositQr }

class DepixFlowNotifier extends AutoDisposeNotifier<DepixStep?>
    with FlowStepMixin<DepixStep> {
  @override
  DepixStep get rootStep => DepixStep.depositsList;

  @override
  DepixStep? build() => null;
}

final depixFlowProvider =
    AutoDisposeNotifierProvider<DepixFlowNotifier, DepixStep?>(
  DepixFlowNotifier.new,
);
