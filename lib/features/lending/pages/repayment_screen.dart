import 'package:aqua/features/lending/models/lending_models.dart';
import 'package:aqua/features/lending/pages/contract_details_screen.dart';
import 'package:aqua/features/lending/providers/lending_provider.dart';
import 'package:aqua/features/lending/providers/selected_offer_provider.dart';
import 'package:aqua/features/lending/widgets/lending_feature_wrapper.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:qr_flutter/qr_flutter.dart';

//WARNING: These screens are all quickly made DEBUG screens. They are not production ready and should be thoroughly revised or re-done.

class RepaymentScreen extends StatelessWidget {
  const RepaymentScreen({super.key});

  static const routeName = '/repayContractScreen';

  @override
  Widget build(BuildContext context) {
    return const LendingFeatureWrapper(
      child: _RepaymentScreen(),
    );
  }
}

class _RepaymentScreen extends HookConsumerWidget {
  const _RepaymentScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contractId = ref.watch(selectedContractIdProvider);
    final contractsState =
        ref.watch(lendingProvider.select((state) => state.value?.contracts));

    final contract = (contractId != null && contractsState?.value != null
        ? contractsState!.value!.firstWhereOrNull((c) => c.id == contractId)
        : null);

    final isLoading = useState(false);
    final txIdController = useTextEditingController();

    if (contract == null) {
      return const Scaffold(
        body: Center(
          child: Text('No contract selected'),
        ),
      );
    }

    // Calculate total owed
    final loanAmount = contract.amount;
    final interestAmount = loanAmount * contract.interestRate;
    final totalOwed = loanAmount + interestAmount;

    // Format the payback date
    final paybackDate = contract.expiresAt;
    final formattedDate =
        '${paybackDate.month}/${paybackDate.day}/${paybackDate.year}';

    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        title: 'Repay Loan',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment details section
            _buildAmountRow(
                'Loan Amount', '\$${loanAmount.toStringAsFixed(2)}'),
            _buildAmountRow(
                'Interest Amount', '\$${interestAmount.toStringAsFixed(2)}'),
            const Divider(height: 32),
            _buildAmountRow('Total Owed', '\$${totalOwed.toStringAsFixed(2)}',
                isBold: true),
            const Divider(height: 32),

            // Payment instructions section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.blue.shade800,
                            ),
                        children: [
                          const TextSpan(
                              text:
                                  'You are expected to pay back your loan by '),
                          TextSpan(
                            text: formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: '. Remember to '),
                          const TextSpan(
                            text: 'pay back in full',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ', with a single transaction; partial repayments are not supported. '
                                'You must pay back using the same asset you borrowed: ${contract.asset.toString().split('.').last}.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // QR Code Section
            Center(
                child: Text('Scan QR code to make payment',
                    style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: contract.repaymentAddress));
                  context.showAquaSnackbar(
                    message: 'Address copied to clipboard',
                    durationSeconds: 2,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: QrImageView(
                    data: contract.repaymentAddress,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('Please send exactly',
                      style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: totalOwed.toString()));
                      context.showAquaSnackbar(
                        message: 'Amount copied to clipboard',
                        durationSeconds: 2,
                      );
                    },
                    child: Text(
                      '\$${totalOwed.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text('to', style: Theme.of(context).textTheme.bodyMedium),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: contract.repaymentAddress));
                      context.showAquaSnackbar(
                        message: 'Address copied to clipboard',
                        durationSeconds: 2,
                      );
                    },
                    child: Text(
                      _shortenAddress(contract.repaymentAddress),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Confirmation instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info, color: Colors.green, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.green.shade800,
                            ),
                        children: const [
                          TextSpan(
                            text:
                                'After sending the repayment amount to the address above, you ',
                          ),
                          TextSpan(
                            text: 'must ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: 'confirm the repayment by providing the ',
                          ),
                          TextSpan(
                            text: 'repayment transaction ID',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text: '. Make sure to provide the ',
                          ),
                          TextSpan(
                            text: 'correct ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                'transaction ID, to allow the lender to verify the repayment. '
                                'Once the lender confirms your repayment, you will be able to claim your collateral.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Transaction ID input
            Text('Repayment Transaction ID',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: txIdController,
              decoration: const InputDecoration(
                hintText: 'e.g. 0x1b3b3d48df236c1e83ab5e7253f885a6f60699963e',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),

            const SizedBox(height: 24),

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  isLoading.value = true;
                  try {
                    // TODO: Implement actual repayment confirmation
                    // Ensure the lending provider is initialized
                    final lendingState = ref.read(lendingProvider);
                    if (lendingState is AsyncData &&
                        !(lendingState.value?.isInitialized ?? false)) {
                      await ref.read(lendingProvider.notifier).initialize();
                    }

                    await ref
                        .read(lendingProvider.notifier)
                        .markAsRepaid(contract.id, txIdController.text);

                    LoanContract updatedContract = await ref
                        .read(lendingProvider.notifier)
                        .getContract(contract.id);

                    if (context.mounted) {
                      // Navigate to contract details with the contract as extra data
                      context.push(ContractDetailsScreen.routeName,
                          extra: updatedContract);
                    }
                  } catch (error) {
                    if (context.mounted) {
                      context.showErrorSnackbar('Error: ${error.toString()}');
                    }
                  } finally {
                    isLoading.value = false;
                  }
                },
                child: Text(
                    isLoading.value ? 'Processing...' : 'Confirm Repayment'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 18 : 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _shortenAddress(String address) {
    if (address.length <= 14) return address;
    return '${address.substring(0, 6)}...${address.substring(address.length - 6)}';
  }
}
