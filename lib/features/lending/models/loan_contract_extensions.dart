import 'package:aqua/features/lending/models/lending_models.dart';

extension LoanContractX on LoanContract {
  bool get shouldShowRepayActionButton {
    return status == ContractStatus.principalGiven ||
        status == ContractStatus.collateralConfirmed;
  }

  bool get shouldShowCancelButton {
    return status == ContractStatus.requested ||
        status == ContractStatus.renewalRequested;
  }

  bool get shouldShowWithdrawCollateralButton {
    return status == ContractStatus.repaymentConfirmed;
  }
}
