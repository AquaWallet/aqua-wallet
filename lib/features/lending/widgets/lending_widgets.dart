import 'package:aqua/features/lending/models/lending_models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

/// A widget that displays a section title and its children
class LendingDetailSection extends StatelessWidget {
  const LendingDetailSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

/// A widget that displays a label-value pair
class LendingDetailItem extends StatelessWidget {
  const LendingDetailItem({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.end,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a loan offer card
class LoanOfferCard extends StatelessWidget {
  final LoanOffer offer;
  final VoidCallback? onTap;

  const LoanOfferCard({
    super.key,
    required this.offer,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(offer.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset: ${offer.asset}'),
            Text('Amount: ${offer.minAmount} - ${offer.maxAmount}'),
            Text(
                'Duration: ${offer.minDurationDays} - ${offer.maxDurationDays} days'),
            Text(
                'Interest Rate: ${(offer.interestRate * 100).toStringAsFixed(2)}%'),
            Text(
                'Min Collateral Ratio: ${(offer.minCollateralRatio * 100).toStringAsFixed(2)}%'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// A widget that displays a loan contract card
class LoanContractCard extends StatelessWidget {
  final LoanContract contract;
  final VoidCallback? onTap;

  const LoanContractCard({
    super.key,
    required this.contract,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text('Contract #${contract.id}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Asset: ${contract.asset}'),
            Text('Amount: ${contract.amount}'),
            Text('Duration: ${contract.durationDays} days'),
            Text('Status: ${contract.status}'),
            Text('Collateral: ${contract.collateralAmountSats} sats'),
            Text(
                'Interest Rate: ${(contract.interestRate * 100).toStringAsFixed(2)}%'),
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

/// A widget that displays a summary item for loan calculations
class LendingSummaryItem extends StatelessWidget {
  const LendingSummaryItem({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

/// Helper function to format a date
String formatDate(DateTime date) {
  return date.formattedDate();
}

/// Helper function to get a color for a contract status
Color getContractStatusColor(ContractStatus status) {
  switch (status) {
    case ContractStatus.requested:
    case ContractStatus.renewalRequested:
      return Colors.orange;
    case ContractStatus.approved:
    case ContractStatus.collateralSeen:
    case ContractStatus.collateralConfirmed:
    case ContractStatus.principalGiven:
      return Colors.green;
    case ContractStatus.repaymentProvided:
    case ContractStatus.repaymentConfirmed:
    case ContractStatus.closed:
    case ContractStatus.extended:
      return Colors.blue;
    case ContractStatus.undercollateralized:
    case ContractStatus.defaulted:
    case ContractStatus.rejected:
    case ContractStatus.requestExpired:
    case ContractStatus.approvalExpired:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

/// Helper function to determine if action buttons should be shown
bool shouldShowActionButtons(ContractStatus status) {
  return status == ContractStatus.principalGiven ||
      status == ContractStatus.collateralConfirmed;
}

/// Helper function to determine if cancel button should be shown
bool shouldShowCancelButton(ContractStatus status) {
  return status == ContractStatus.requested ||
      status == ContractStatus.renewalRequested;
}
