import 'package:aqua/features/lending/models/lending_models.dart';
import 'package:aqua/features/lending/pages/contract_details_screen.dart';
import 'package:aqua/features/lending/providers/lending_provider.dart';
import 'package:aqua/features/lending/widgets/lending_feature_wrapper.dart';
import 'package:aqua/features/lending/widgets/lending_widgets.dart';
import 'package:aqua/features/receive/providers/receive_asset_address_provider.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

//WARNING: These screens are all quickly made DEBUG screens. They are not production ready and should be thoroughly revised or re-done.

class CreateContractScreen extends ConsumerWidget {
  const CreateContractScreen({super.key});

  static const routeName = '/createContractScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOfferAsync = ref
        .watch(lendingProvider.select((state) => state.value?.selectedOffer));

    return selectedOfferAsync?.when(
          data: (offer) {
            if (offer == null) {
              // Offer not found or ID was null, show an error or placeholder
              return const Scaffold(
                  body: Center(child: Text('Selected offer not available.')));
            }
            return LendingFeatureWrapper(
              child: _CreateContractScreen(offer: offer),
            );
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, st) =>
              Scaffold(body: Center(child: Text('Error loading offer: $e'))),
        ) ??
        const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _CreateContractScreen extends HookConsumerWidget {
  const _CreateContractScreen({
    required this.offer,
  });

  final LoanOffer offer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final loanAmountController = useTextEditingController();
    final durationController = useTextEditingController();

    // Watch the lendingProvider itself to get its AsyncValue state (isLoading, hasError, etc.)
    final lendingAsyncValue = ref.watch(lendingProvider);

    useEffect(() {
      Future.microtask(() async {
        final lendingStateValue = ref.read(lendingProvider).value;
        if (lendingStateValue != null && !lendingStateValue.isInitialized) {
          await ref.read(lendingProvider.notifier).initialize();
        }
      });
      return null;
    }, const []);

    // Watch bitcoin address
    final btcAddressAsync = ref.watch(
      receiveAssetAddressProvider((Asset.btc(), null)),
    );

    // Calculate fees and required collateral based on input values
    final calculations = useMemoized(() {
      if (loanAmountController.text.isEmpty ||
          durationController.text.isEmpty) {
        return null;
      }

      final loanAmount = double.tryParse(loanAmountController.text);
      final duration = int.tryParse(durationController.text);

      if (loanAmount == null || duration == null) {
        return null;
      }

      // Find the applicable origination fee based on duration
      final originationFee = offer.originationFees.firstWhere(
        (fee) => duration >= fee.fromDay && duration <= fee.toDay,
        orElse: () => offer.originationFees.last,
      );

      final interestAmount = loanAmount * offer.interestRate * (duration / 365);
      final originationFeeAmount = loanAmount * originationFee.fee;
      final totalRepaymentAmount =
          loanAmount + interestAmount + originationFeeAmount;

      // Calculate required collateral based on minimum collateral ratio
      final requiredCollateral = (loanAmount / offer.minCollateralRatio).ceil();

      return {
        'interestAmount': interestAmount,
        'originationFeeAmount': originationFeeAmount,
        'totalRepaymentAmount': totalRepaymentAmount,
        'requiredCollateral': requiredCollateral,
      };
    }, [loanAmountController.text, durationController.text]);

    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        title: 'Create Loan Request',
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Loan Details',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: loanAmountController,
              decoration: InputDecoration(
                labelText: 'Loan Amount (${offer.asset})',
                hintText:
                    'Enter amount between ${offer.minAmount} and ${offer.maxAmount}',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a loan amount';
                }
                final amount = double.tryParse(value);
                if (amount == null) {
                  return 'Please enter a valid number';
                }
                if (amount < offer.minAmount) {
                  return 'Amount must be at least ${offer.minAmount}';
                }
                if (amount > offer.maxAmount) {
                  return 'Amount must be at most ${offer.maxAmount}';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: durationController,
              decoration: InputDecoration(
                labelText: 'Duration (days)',
                hintText:
                    'Enter duration between ${offer.minDurationDays} and ${offer.maxDurationDays} days',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a duration';
                }
                final days = int.tryParse(value);
                if (days == null) {
                  return 'Please enter a valid number';
                }
                if (days < offer.minDurationDays) {
                  return 'Duration must be at least ${offer.minDurationDays} days';
                }
                if (days > offer.maxDurationDays) {
                  return 'Duration must be at most ${offer.maxDurationDays} days';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (calculations != null) ...[
              Text(
                'Loan Summary',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              LendingSummaryItem(
                label: 'Interest',
                value:
                    '${calculations['interestAmount']?.toStringAsFixed(2)} ${offer.asset}',
              ),
              const SizedBox(height: 8),
              LendingSummaryItem(
                label: 'Origination Fee',
                value:
                    '${calculations['originationFeeAmount']?.toStringAsFixed(2)} ${offer.asset}',
              ),
              const SizedBox(height: 8),
              LendingSummaryItem(
                label: 'Total Repayment',
                value:
                    '${calculations['totalRepaymentAmount']?.toStringAsFixed(2)} ${offer.asset}',
              ),
              const SizedBox(height: 8),
              LendingSummaryItem(
                label: 'Required Collateral',
                value: '${calculations['requiredCollateral']} sats',
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Receiving Address',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            btcAddressAsync.when(
              data: (address) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Bitcoin address for receiving the loan:',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            address,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(receiveAssetAddressProvider((Asset.btc(), null))
                            .notifier)
                        .forceRefresh(),
                    child: const Text('Generate New Address'),
                  ),
                ],
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stackTrace) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Error loading address: ${error.toString()}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.red,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(
                      receiveAssetAddressProvider((Asset.btc(), null)),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            if (lendingAsyncValue.hasError &&
                lendingAsyncValue.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${lendingAsyncValue.error.toString()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.red.shade900,
                      ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: lendingAsyncValue.isLoading
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final btcAddress = btcAddressAsync.valueOrNull;
                        if (btcAddress == null) {
                          context.showAquaSnackbar(
                            message: 'Please wait for address generation',
                          );
                          return;
                        }

                        try {
                          // Ensure the lending provider is initialized - this check might be redundant
                          // if the useEffect above guarantees initialization before this point.
                          final lendingStateValue =
                              ref.read(lendingProvider).value;
                          if (lendingStateValue != null &&
                              !lendingStateValue.isInitialized) {
                            await ref
                                .read(lendingProvider.notifier)
                                .initialize();
                          }

                          final request = ContractRequest(
                              id: offer.id,
                              loanAmount:
                                  double.parse(loanAmountController.text),
                              durationDays: int.parse(durationController.text),
                              borrowerBtcAddress: btcAddress,
                              // TODO: get the users xpub
                              borrowerPk:
                                  '0235f48bffd7c454f36111acd5ed73456a80d212f0b66b276d55dc473ac9149697', // Mock xpub for testing
                              borrowerDerivationPath: 'm/10101/0/1',
                              borrowerNpub: "npubRandomString",
                              loanType: LoanType.stablecoin,
                              // TODO: get a loan address
                              borrowerLoanAddress: "something");

                          final contract = await ref
                              .read(lendingProvider.notifier)
                              .requestContract(request);

                          if (context.mounted) {
                            context.push(ContractDetailsScreen.routeName,
                                extra: contract);
                          }
                        } catch (e) {
                          // Error is now handled by watching lendingAsyncValue.hasError
                          // But, a SnackBar can still be useful for transient errors.
                          if (context.mounted) {
                            context.showErrorSnackbar('Error: ${e.toString()}');
                          }
                        }
                      },
                child: lendingAsyncValue.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Contract Request'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
