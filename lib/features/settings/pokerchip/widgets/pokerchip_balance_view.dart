import 'package:aqua/features/settings/pokerchip/pokerchip.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class PokerchipBalanceCard extends HookConsumerWidget {
  const PokerchipBalanceCard({
    super.key,
    required this.data,
  });

  final PokerchipBalanceState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        children: [
          //ANCHOR: Balance Title
          const SizedBox(height: 31.0),
          Text(
            context.loc.pokerChipBalanceLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 26.0,
                  fontWeight: FontWeight.w400,
                ),
          ),
          const SizedBox(height: 24.0),
          //ANCHOR - Asset Icon
          PokerchipAssetIcon(data.asset),
          const SizedBox(height: 26.0),
          //ANCHOR: Balance value
          CopyableTextView(
            text: data.balance.toUpperCase(),
            iconSize: 14.0,
            textAlign: TextAlign.center,
            textStyle: Theme.of(context).textTheme.titleLarge,
            margin: const EdgeInsetsDirectional.symmetric(horizontal: 40.0),
          ),
          const SizedBox(height: 24.0),
          //ANCHOR - Address
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            child: CopyableAddressView(address: data.address),
          ),
          const SizedBox(height: 21.0),
        ],
      ),
    );
  }
}
