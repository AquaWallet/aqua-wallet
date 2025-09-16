import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/settings/manage_assets/keys/manage_assets_screen_keys.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_svg/svg.dart';
import 'package:coin_cz/config/config.dart';

class ManageAssetListItemTile extends StatelessWidget {
  const ManageAssetListItemTile({
    super.key,
    required this.asset,
    required this.isUserAsset,
    this.onAdd,
    this.onRemove,
  });

  final Asset asset;
  final bool isUserAsset;
  final Function(Asset asset)? onAdd;
  final Function(Asset asset)? onRemove;

  @override
  Widget build(BuildContext context) {
    return BoxShadowCard(
      borderRadius: BorderRadius.circular(20.0),
      bordered: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.0),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20.0),
          child: Container(
            height: 82.0,
            padding: const EdgeInsets.only(left: 17.0, right: 8.0),
            child: Row(
              children: [
                //ANCHOR - Icon
                if (asset.isLBTC)
                  SvgPicture.asset(
                    Svgs.layerTwoSingle,
                    fit: BoxFit.fitWidth,
                    width: 52.0,
                    height: 52.0,
                  ),
                if (!asset.isLBTC)
                  SvgPicture.network(
                    asset.logoUrl,
                    width: 52.0,
                    height: 52.0,
                  ),

                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //ANCHOR - Name
                      Text(
                        asset.isLBTC ? context.loc.layer2Bitcoin : asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      //ANCHOR - Ticker
                      Text(
                        asset.ticker,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isUserAsset) ...[
                  //ANCHOR - Remove Button
                  if (asset.isRemovable) ...[
                    AquaOutlinedIconButton(
                      key: ManageAssetsScreenKeys.manageAssetRemoveButton,
                      onPressed: () => onRemove?.call(asset),
                      size: 40.0,
                      child: Icon(
                        Icons.remove,
                        size: 24.0,
                        color: Theme.of(context).colors.onBackground,
                      ),
                    ),
                    const SizedBox(width: 4.0),
                  ],
                  //ANCHOR - Drag Button
                  IconButton(
                    key: ManageAssetsScreenKeys.manageAssetDragButton,
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    splashRadius: 20.0,
                    icon: Icon(
                      Icons.menu,
                      size: 22.0,
                      color: Theme.of(context).colors.onBackground,
                    ),
                  )
                ] else ...[
                  //ANCHOR - Add Button
                  AquaOutlinedIconButton(
                    key: ManageAssetsScreenKeys
                        .manageAssetAddSpecificAssetButton,
                    onPressed: () => onAdd?.call(asset),
                    size: 40.0,
                    child: Icon(
                      Icons.add,
                      size: 24.0,
                      color: Theme.of(context).colors.onBackground,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
