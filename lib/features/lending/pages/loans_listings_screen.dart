import 'package:aqua/features/lending/lending.dart';
import 'package:aqua/features/lending/providers/selected_offer_provider.dart';
import 'package:aqua/features/shared/shared.dart';

//WARNING: These screens are all quickly made DEBUG screens. They are not production ready and should be thoroughly revised or re-done.

class LoansListingsScreen extends StatelessWidget {
  const LoansListingsScreen({super.key});

  static const routeName = '/loansListingsScreen';

  @override
  Widget build(BuildContext context) {
    return const LendingFeatureWrapper(
      child: _LoansListingsScreen(),
    );
  }
}

class _LoansListingsScreen extends ConsumerWidget {
  const _LoansListingsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lendingState = ref.watch(lendingProvider);

    return lendingState.when(
      data: (state) {
        if (!state.isInitialized) {
          Future.microtask(
              () => ref.read(lendingProvider.notifier).initialize());
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Loans'),
              bottom: TabBar(
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: const [
                  Tab(text: 'Loan Offers'),
                  Tab(text: 'My Contracts'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _LoanOffersTab(),
                _ContractsTab(),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _LoanOffersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(lendingProvider
        .select((state) => state.value?.offers ?? const AsyncValue.loading()));

    return offers.when(
      data: (offers) {
        if (offers.isEmpty) {
          return const Center(
            child: Text('No loan offers available'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(lendingProvider.notifier).refreshAll(),
          child: ListView.builder(
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return LoanOfferCard(
                offer: offer,
                onTap: () {
                  ref.read(selectedOfferIdProvider.notifier).state = offer.id;
                  context.push(CreateContractScreen.routeName);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(lendingProvider.notifier).refreshAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contracts = ref.watch(lendingProvider.select(
        (state) => state.value?.contracts ?? const AsyncValue.loading()));

    return contracts.when(
      data: (contracts) {
        if (contracts.isEmpty) {
          return const Center(
            child: Text('No contracts found'),
          );
        }

        return RefreshIndicator(
          onRefresh: () => ref.read(lendingProvider.notifier).refreshAll(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contracts.length,
            itemBuilder: (context, index) {
              final contract = contracts[index];
              return LoanContractCard(
                contract: contract,
                onTap: () {
                  context.push(ContractDetailsScreen.routeName,
                      extra: contract);
                },
              );
            },
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stackTrace) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${error.toString()}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(lendingProvider.notifier).refreshAll(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class LoanOfferDetailsScreen extends ConsumerWidget {
  const LoanOfferDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedOffer = ref.watch(
        lendingProvider.select((state) => state.value?.offers.value?.firstWhere(
              (offer) => offer.id == ref.read(selectedOfferIdProvider),
              orElse: () => throw StateError('Offer not found'),
            )));

    if (selectedOffer == null) {
      return const Scaffold(
        body: Center(
          child: Text('No offer selected'),
        ),
      );
    }

    return Scaffold(
      appBar: const AquaAppBar(
        showBackButton: true,
        title: 'Loan Offer Details',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedOffer.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            LendingDetailSection(
              title: 'Loan Terms',
              children: [
                LendingDetailItem(
                  label: 'Asset',
                  value: selectedOffer.asset.toString().split('.').last,
                ),
                LendingDetailItem(
                  label: 'Amount Range',
                  value:
                      '${selectedOffer.minAmount} - ${selectedOffer.maxAmount}',
                ),
                LendingDetailItem(
                  label: 'Duration',
                  value:
                      '${selectedOffer.minDurationDays} - ${selectedOffer.maxDurationDays} days',
                ),
                LendingDetailItem(
                  label: 'Interest Rate',
                  value:
                      '${(selectedOffer.interestRate * 100).toStringAsFixed(2)}%',
                ),
                LendingDetailItem(
                  label: 'Min Collateral Ratio',
                  value:
                      '${(selectedOffer.minCollateralRatio * 100).toStringAsFixed(2)}%',
                ),
              ],
            ),
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Lender Information',
              children: [
                LendingDetailItem(
                  label: 'Name',
                  value: selectedOffer.lender.name,
                ),
                LendingDetailItem(
                  label: 'Successful Loans',
                  value: selectedOffer.lender.successfulContracts.toString(),
                ),
                LendingDetailItem(
                  label: 'Failed Loans',
                  value: selectedOffer.lender.failedContracts.toString(),
                ),
                LendingDetailItem(
                  label: 'Rating',
                  value: selectedOffer.lender.rating.toString(),
                ),
                LendingDetailItem(
                  label: 'Member Since',
                  value: formatDate(selectedOffer.lender.joinedAt),
                ),
              ],
            ),
            const SizedBox(height: 24),
            LendingDetailSection(
              title: 'Origination Fees',
              children: selectedOffer.originationFees
                  .map((fee) => LendingDetailItem(
                        label: '${fee.fromDay}-${fee.toDay} days',
                        value: '${(fee.fee * 100).toStringAsFixed(2)}%',
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedOffer.status == LoanOfferStatus.available
                    ? () {
                        context.push(
                            '/lending/create_contract/${selectedOffer.id}');
                      }
                    : null,
                child: const Text('Request Loan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
