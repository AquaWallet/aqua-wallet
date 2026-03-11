import 'dart:math' as math;

import 'package:aqua/features/lending/models/lending_models.dart';
import 'package:aqua/features/lending/models/loan_contract_extensions.dart';
import 'package:aqua/features/lending/pages/repayment_screen.dart';
import 'package:aqua/features/lending/pages/withdraw_collateral_screen.dart';
import 'package:aqua/features/lending/providers/lending_provider.dart';
import 'package:aqua/features/lending/providers/selected_offer_provider.dart';
import 'package:aqua/features/lending/widgets/lending_feature_wrapper.dart';
import 'package:aqua/features/lending/widgets/lending_widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_flutter/qr_flutter.dart';

//WARNING: These screens are all quickly made DEBUG screens. They are not production ready and should be thoroughly revised or re-done.
class ContractDetailsScreen extends StatelessWidget {
  const ContractDetailsScreen({super.key});

  static const routeName = '/contractDetailsScreen';

  @override
  Widget build(BuildContext context) {
    return const LendingFeatureWrapper(
      child: _ContractDetailsScreen(),
    );
  }
}

class _ContractDetailsScreen extends HookConsumerWidget {
  const _ContractDetailsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine which contract to display
    final contractId = ref.watch(selectedContractIdProvider);
    final contractsState =
        ref.watch(lendingProvider.select((state) => state.value?.contracts));

    final selectedContract =
        contractsState?.value?.firstWhereOrNull((c) => c.id == contractId);

    if (selectedContract == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isLoading = useState(false);

    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        title: 'Contract Details',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Contract #${selectedContract.id.substring(0, math.min(8, selectedContract.id.length))}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getContractStatusColor(selectedContract.status),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    selectedContract.status
                        .toString()
                        .split('.')
                        .last
                        .toUpperCase(),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Loan Details',
              children: [
                LendingDetailItem(
                  label: 'Asset',
                  value: selectedContract.asset.toString().split('.').last,
                ),
                LendingDetailItem(
                  label: 'Amount',
                  value: selectedContract.amount.toString(),
                ),
                LendingDetailItem(
                  label: 'Duration',
                  value: '${selectedContract.durationDays} days',
                ),
                LendingDetailItem(
                  label: 'Interest Rate',
                  value:
                      '${(selectedContract.interestRate * 100).toStringAsFixed(2)}%',
                ),
                LendingDetailItem(
                  label: 'Initial Collateral Ratio',
                  value:
                      '${(selectedContract.initialCollateralRatio * 100).toStringAsFixed(2)}%',
                ),
              ],
            ),
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Collateral',
              children: [
                LendingDetailItem(
                  label: 'Initial Amount',
                  value: '${selectedContract.initialCollateralSats} sats',
                ),
                LendingDetailItem(
                  label: 'Current Amount',
                  value: '${selectedContract.collateralAmountSats} sats',
                ),
                LendingDetailItem(
                  label: 'Status',
                  value: selectedContract.liquidationStatus
                      .toString()
                      .split('.')
                      .last,
                ),
                LendingDetailItem(
                  label: 'Liquidation Price',
                  value: '\$${selectedContract.liquidationPrice}',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (selectedContract.status == ContractStatus.approved) ...[
              const SizedBox(height: 24),
              LendingDetailSection(
                title: 'Funding Details',
                children: [
                  LendingDetailItem(
                    label: 'Contract Address',
                    value: selectedContract.contractAddress ?? 'Not available',
                    // Add a copy button for the contract address
                    trailing: selectedContract.contractAddress != null
                        ? IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: selectedContract.contractAddress!));
                              context.showAquaSnackbar(
                                message: 'Address copied to clipboard',
                                durationSeconds: 2,
                              );
                            },
                          )
                        : null,
                  ),
                  LendingDetailItem(
                    label: 'Required Collateral',
                    value: '${selectedContract.initialCollateralSats} sats',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // QR Code Widget
              Center(
                child: selectedContract.contractAddress != null
                    ? Column(
                        children: [
                          QrImageView(
                            data: selectedContract.contractAddress!,
                            version: QrVersions.auto,
                            size: 200.0,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan to fund with external wallet',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      )
                    : const Text('Contract address not available'),
              ),
              const SizedBox(height: 24),
              // Fund with wallet button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          isLoading.value = true;
                          try {
                            // TODO: Implement funding flow
                            // This would typically open your app's wallet to send funds
                            // to the contract address
                            await _fundContractFromWallet(
                                context,
                                selectedContract.contractAddress!,
                                selectedContract.initialCollateralSats);
                          } catch (error) {
                            if (!context.mounted) return;

                            context.showErrorSnackbar(
                              'Error: ${error.toString()}',
                            );
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Text('Fund with Wallet'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Addresses',
              children: [
                LendingDetailItem(
                  label: 'Borrower Address',
                  value: selectedContract.borrowerAddress,
                ),
                LendingDetailItem(
                  label: 'Repayment Address',
                  value: selectedContract.repaymentAddress,
                ),
              ],
            ),
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Dates',
              children: [
                LendingDetailItem(
                  label: 'Created',
                  value: formatDate(selectedContract.createdAt),
                ),
                LendingDetailItem(
                  label: 'Updated',
                  value: formatDate(selectedContract.updatedAt),
                ),
                LendingDetailItem(
                  label: 'Expires',
                  value: formatDate(selectedContract.expiresAt),
                ),
                if (selectedContract.repaidAt != null)
                  LendingDetailItem(
                    label: 'Repaid',
                    value: formatDate(selectedContract.repaidAt!),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Transactions',
              children: selectedContract.transactions
                  .map((tx) => LendingDetailItem(
                        label: tx.type.toString().split('.').last,
                        value: '${formatDate(tx.timestamp)} - ${tx.txid}',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            if (selectedContract.shouldShowRepayActionButton) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          isLoading.value = true;
                          try {
                            // Navigate to the repayment screen
                            context.push(RepaymentScreen.routeName,
                                extra: selectedContract);
                            // ignore: unused_result
                            ref.refresh(lendingProvider);
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  child: const Text('Repay Loan'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          // TODO: Implement extension flow
                          isLoading.value = true;
                          try {
                            // Show extension dialog
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  child: const Text('Extend Contract'),
                ),
              ),
            ],
            if (selectedContract.shouldShowWithdrawCollateralButton) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          isLoading.value = true;
                          try {
                            // Navigate to the repayment screen
                            context.push(WithdrawCollateralScreen.routeName,
                                extra: selectedContract);
                            // ignore: unused_result
                            ref.refresh(lendingProvider);
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  child: const Text('Withdraw collateral'),
                ),
              ),
            ],
            if (selectedContract.shouldShowCancelButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading.value
                      ? null
                      : () async {
                          isLoading.value = true;
                          try {
                            // TODO: Implement cancel flow
                            Navigator.of(context).pop();
                          } catch (error) {
                            context.showErrorSnackbar(
                              'Error: ${error.toString()}',
                            );
                          } finally {
                            isLoading.value = false;
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: const Text('Cancel Request'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String formatDate(DateTime date) {
    return date.formattedDate();
  }

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
}

Future<void> _fundContractFromWallet(
    BuildContext context, String contractAddress, int amountSats) async {
  // For now, just show a dialog
  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Fund Contract'),
      content: Text(
          'This would open your wallet to send $amountSats sats to $contractAddress'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
