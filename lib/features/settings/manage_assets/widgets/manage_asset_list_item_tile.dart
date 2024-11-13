import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

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
      borderRadius: BorderRadius.circular(20.r),
      bordered: false,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(20.r),
          child: Container(
            height: 82.h,
            padding: EdgeInsets.only(left: 17.w, right: 8.w),
            child: Row(
              children: [
                //ANCHOR - Icon
                if (asset.isLBTC)
                  SvgPicture.asset(
                    Svgs.layerTwoSingle,
                    fit: BoxFit.fitWidth,
                    width: 52.r,
                    height: 52.r,
                  ),
                if (!asset.isLBTC)
                  SvgPicture.network(
                    asset.logoUrl,
                    width: 52.r,
                    height: 52.r,
                  ),

                SizedBox(width: 14.w),
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
                              fontSize: 18.sp,
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
                      onPressed: () => onRemove?.call(asset),
                      size: 40.r,
                      child: Icon(
                        Icons.remove,
                        size: 24.r,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    ),
                    SizedBox(width: 4.w),
                  ],
                  //ANCHOR - Drag Button
                  IconButton(
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    splashRadius: 20.r,
                    icon: Icon(
                      Icons.menu,
                      size: 22.r,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  )
                ] else ...[
                  //ANCHOR - Add Button
                  AquaOutlinedIconButton(
                    onPressed: () => onAdd?.call(asset),
                    size: 40.r,
                    child: Icon(
                      Icons.add,
                      size: 24.r,
                      color: Theme.of(context).colorScheme.onBackground,
                    ),
                  ),
                  SizedBox(width: 12.w),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
