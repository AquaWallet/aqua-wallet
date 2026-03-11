import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class SectionAssetList extends StatelessWidget {
  const SectionAssetList({
    super.key,
    required this.items,
  });

  final List<Asset> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: AquaPrimitiveColors.shadow,
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ListView.separated(
          primary: false,
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(
            height: 0,
            thickness: 1,
            color: context.aquaColors.surfaceBackground,
          ),
          itemBuilder: (context, index) => AssetListItem(
            asset: items[index],
          ),
        ),
      ),
    );
  }
}
