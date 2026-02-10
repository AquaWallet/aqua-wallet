import 'package:aqua/features/lending/models/lending_models.dart';
import 'package:aqua/features/lending/pages/contract_details_screen.dart';
import 'package:aqua/features/lending/providers/lending_provider.dart';
import 'package:aqua/features/lending/providers/selected_offer_provider.dart';
import 'package:aqua/features/lending/widgets/lending_feature_wrapper.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

//WARNING: These screens are all quickly made DEBUG screens. They are not production ready and should be thoroughly revised or re-done.

class WithdrawCollateralScreen extends StatelessWidget {
  const WithdrawCollateralScreen({super.key});

  static const routeName = '/withdrawCollateralScreen';

  @override
  Widget build(BuildContext context) {
    return const LendingFeatureWrapper(
      child: _WithdrawCollateralScreen(),
    );
  }
}

class _WithdrawCollateralScreen extends HookConsumerWidget {
  const _WithdrawCollateralScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First try to get contract from route
    final contractFromRoute = GoRouterState.of(context).extra as LoanContract?;

    // If we have a contract from route, update the provider state after the frame
    useEffect(() {
      if (contractFromRoute != null) {
        // Use a post-frame callback to avoid modifying providers during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(selectedContractIdProvider.notifier).state =
              contractFromRoute.id;
        });
      }
      return null;
    }, [contractFromRoute?.id]);

    // If no contract from route, get from provider
    final contractId = ref.watch(selectedContractIdProvider);
    final contractsState =
        ref.watch(lendingProvider.select((state) => state.value?.contracts));

    // Determine which contract to display
    final contract = contractFromRoute ??
        (contractId != null && contractsState?.value != null
            ? contractsState!.value!
                .where((c) => c.id == contractId)
                .firstOrNull
            : null);

    final isLoading = useState(false);
    final feeRateController = useTextEditingController();

    if (contract == null) {
      return const Scaffold(
        body: Center(
          child: Text('No contract selected'),
        ),
      );
    }

    // Get the collateral amount
    final collateralAmount = contract.collateralAmountSats / 100000000;

    // Get the withdrawal address from the contract
    final withdrawalAddress = contract.borrowerAddress;

    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        title: 'Withdraw Collateral',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Collateral details section
            _buildAmountRow('Collateral Amount',
                '${collateralAmount.toStringAsFixed(8)} BTC',
                isBold: true),
            const Divider(height: 32),

            // Withdrawal instructions section
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
                        children: const [
                          TextSpan(
                              text:
                                  'You can now withdraw your collateral as the loan has been '),
                          TextSpan(
                            text: 'successfully repaid',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                '. Your collateral will be sent to the address below. Make sure to set an appropriate '
                                'transaction fee to ensure timely processing.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Withdrawal address section
            // QR Code Section
            Center(
                child: Text('Verify Withdrawal Address',
                    style: Theme.of(context).textTheme.titleMedium)),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      withdrawalAddress,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, color: Colors.blue),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: withdrawalAddress));
                      context.showAquaSnackbar(
                        message: 'Address copied to clipboard',
                        durationSeconds: 2,
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text('You will receive approximately',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${collateralAmount.toStringAsFixed(8)} BTC',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text('minus network fees',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Transaction fee input
            Text('Transaction Fee (sats/vbyte)',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: feeRateController,
              decoration: const InputDecoration(
                hintText: 'e.g. 5',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              maxLines: 1,
            ),

            const SizedBox(height: 16),

            // Fee explanation
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber,
                      color: Colors.amber, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.amber.shade900,
                            ),
                        children: const [
                          TextSpan(text: 'Higher fee rates result in '),
                          TextSpan(
                            text: 'faster confirmation times',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          TextSpan(
                            text:
                                ' but increase the cost. Lower fee rates are cheaper but may result in '
                                'longer waiting times for your transaction to be confirmed.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Withdraw button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        // Validate fee rate
                        final feeRateText = feeRateController.text.trim();
                        if (feeRateText.isEmpty) {
                          context.showAquaSnackbar(
                            message: 'Please enter a fee rate',
                          );
                          return;
                        }

                        final feeRate = int.tryParse(feeRateText);
                        if (feeRate == null || feeRate <= 0) {
                          context.showAquaSnackbar(
                            message: 'Please enter a valid fee rate',
                          );
                          return;
                        }

                        isLoading.value = true;
                        try {
                          // Ensure the lending provider is initialized
                          final lendingState = ref.read(lendingProvider);
                          if (lendingState is AsyncData &&
                              !(lendingState.value?.isInitialized ?? false)) {
                            await ref
                                .read(lendingProvider.notifier)
                                .initialize();
                          }

                          // Call the withdraw collateral method
                          await ref
                              .read(lendingProvider.notifier)
                              .signWithdrawalTransaction(contract.id, feeRate);

                          // // Get updated contract
                          LoanContract updatedContract = await ref
                              .read(lendingProvider.notifier)
                              .getContract(contract.id);

                          if (context.mounted) {
                            // Show success message
                            context.showSuccessSnackbar(
                              'Withdrawal transaction submitted successfully',
                            );

                            // Navigate to contract details with the updated contract as extra data
                            context.push(ContractDetailsScreen.routeName,
                                extra: updatedContract);
                          }
                        } catch (error) {
                          if (context.mounted) {
                            context.showErrorSnackbar(
                              'Error: ${error.toString()}',
                            );
                          }
                        } finally {
                          isLoading.value = false;
                        }
                      },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    isLoading.value ? 'Processing...' : 'Withdraw Collateral',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
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
}
