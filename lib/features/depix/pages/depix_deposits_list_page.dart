import 'package:aqua/data/provider/format_provider.dart';
import 'package:aqua/features/depix/depix.dart';
import 'package:aqua/features/depix/utils/status_label.dart';
import 'package:aqua/features/settings/exchange_rate/models/exchange_rate.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:intl/intl.dart';
import 'package:ui_components/ui_components.dart';

class DepixDepositsListPage extends ConsumerWidget {
  const DepixDepositsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final format = ref.watch(formatProvider);
    final brlFormat = FiatCurrency.brl.format;
    final depositsAsync = ref.watch(depixDepositsListProvider);
    final deposits =
        depositsAsync.valueOrNull?.deposits ?? const <EulenDeposit>[];
    final ctaLocked = deposits.any((d) => d.status.isUnderReview);
    final ctaLabel = ctaLocked
        ? context.loc.depixDepositsListDepositUnderReview
        : deposits.any((d) => d.status.isPending)
            ? context.loc.depixDepositsListContinuePendingDeposit
            : context.loc.depixDepositsListNewDeposit;

    return Scaffold(
      body: depositsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(context.loc.somethingWentWrong)),
        data: (response) {
          final deposits = response?.deposits ?? [];
          if (deposits.isEmpty) {
            return AquaPullToRefresh(
              colors: context.aquaColors,
              enablePullDown: true,
              onRefresh: () async {
                await ref
                    .read(depixDepositsListProvider.notifier)
                    .refreshDeposits();
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Center(
                      child: Text(context.loc.depixDepositsListEmpty),
                    ),
                  ),
                ],
              ),
            );
          }
          return AquaPullToRefresh(
            colors: context.aquaColors,
            enablePullDown: true,
            onRefresh: () async {
              await ref
                  .read(depixDepositsListProvider.notifier)
                  .refreshDeposits();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                itemCount: deposits.length,
                itemBuilder: (context, index) {
                  final deposit = deposits[index];
                  final amountBrl = amountEntryFormatFiatNumeric(
                    format,
                    Decimal.parse(deposit.amountBrlCents.asBrl.toString()),
                    brlFormat,
                    padZeroDecimals: false,
                    withSymbol: true,
                  );
                  final date =
                      DateFormat('MMM d, yyyy').format(deposit.created);
                  return AquaListItem(
                    title: amountBrl,
                    subtitle: date,
                    colors: context.aquaColors,
                    iconTrailing: AquaChipLabel(
                      message: deposit.status.label(context),
                      variant: deposit.status.statusVariant(deposit.status),
                      margin: EdgeInsets.zero,
                      colors: context.aquaColors,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: AquaButton.primary(
          onPressed: ctaLocked
              ? null
              : () =>
                  ref.read(depixDepositsListProvider.notifier).onCtaPressed(),
          text: ctaLabel,
        ),
      ),
    );
  }
}
