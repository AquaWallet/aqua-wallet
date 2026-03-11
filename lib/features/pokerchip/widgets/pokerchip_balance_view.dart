import 'package:aqua/features/pokerchip/pokerchip.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class PokerchipBalanceCard extends HookConsumerWidget {
  const PokerchipBalanceCard({
    super.key,
    required this.data,
  });

  final PokerchipBalanceState data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BoxShadowCard(
      borderRadius: BorderRadius.circular(12.0),
      child: Column(
        children: [
          //ANCHOR - Asset Icon
          PokerchipAssetIcon(data.asset),
          const SizedBox(height: 26.0),
          //ANCHOR: Balance value
          AquaCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      AquaAssetIcon.fromAssetId(
                        assetId: data.asset.id,
                        size: 24,
                      ),
                      const SizedBox(width: 8.0),
                      AquaText.body1SemiBold(
                        text: context.loc.balance,
                      ),
                      const Spacer(),
                      AquaText.body1SemiBold(text: data.balance.toUpperCase())
                    ],
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  CopyableAddressView(
                    address: data.address.toLowerCase(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
