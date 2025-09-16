import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';

class SectionAssetList extends StatelessWidget {
  const SectionAssetList({
    super.key,
    required this.items,
  });

  final List<Asset> items;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      primary: false,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14.0),
      itemBuilder: (context, index) => AssetListItem(
        asset: items[index],
      ),
    );
  }
}
