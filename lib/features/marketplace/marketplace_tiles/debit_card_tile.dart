import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_button.dart';
import 'package:aqua/features/private_integrations/debit_card/debit_card.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class DebitCardTile extends ConsumerWidget {
  const DebitCardTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availabilityAsync = ref.watch(debitCardAvailabilityProvider);

    return availabilityAsync.when(
      data: (isAvailable) => _DebitCardMarketplaceTile(
        isDisabled: !(isAvailable),
        subtitle:
            !isAvailable ? context.loc.marketplaceTileDisabledMessage : null,
        onPressed: () => context.push(DebitCardMyCardScreen.routeName),
      ),
      loading: () => const _DebitCardMarketplaceTile(
        isDisabled: true,
        onPressed: null,
      ),
      error: (error, stack) => const _DebitCardMarketplaceTile(
        isDisabled: true,
        onPressed: null,
      ),
    );
  }
}

class _DebitCardMarketplaceTile extends StatelessWidget {
  const _DebitCardMarketplaceTile({
    this.subtitle,
    required this.isDisabled,
    this.onPressed,
  });

  final String? subtitle;
  final bool isDisabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => MarketplaceButton(
        title: context.loc.marketplaceScreenDolphinCardButton,
        subtitle: subtitle ??
            context.loc.marketplaceScreenDolphinCardButtonDescription,
        icon: Svgs.marketplaceBankings,
        onPressed: onPressed,
        isDisabled: isDisabled,
      );
}
