import 'package:aqua/common/providers/flow_step_notifier.dart';
import 'package:aqua/features/shared/shared.dart';

enum LnAddressEditStep {
  pay,
  confirm,
}

class LnAddressEditFlowNotifier extends AutoDisposeNotifier<LnAddressEditStep?>
    with FlowStepMixin<LnAddressEditStep> {
  @override
  LnAddressEditStep get rootStep => LnAddressEditStep.pay;

  @override
  LnAddressEditStep? build() => null;
}

final lnAddressEditStepProvider =
    AutoDisposeNotifierProvider<LnAddressEditFlowNotifier, LnAddressEditStep?>(
  LnAddressEditFlowNotifier.new,
);
