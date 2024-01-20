import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';

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
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (context, index) => AssetListItem(
        asset: items[index],
      ),
    );
  }
}
