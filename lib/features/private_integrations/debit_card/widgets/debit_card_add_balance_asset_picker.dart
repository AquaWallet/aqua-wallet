import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebitCardAddBalanceAssetPicker extends HookConsumerWidget {
  const DebitCardAddBalanceAssetPicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAssetPickerExpanded = useState(false);
    final input = ref.watch(topUpInputStateProvider).value!;

    return PopupMenuButton(
      position: PopupMenuPosition.under,
      // Use radius values to make offsets to match the shape cutout
      offset: const Offset(0, -20),
      clipBehavior: Clip.hardEdge,
      elevation: 0,
      shape: AssetSelectorFieldCutOutShape(
        radius: 12,
        borderColor: context.colors.popUpMenuButtonSwapScreenBorderColor,
      ),
      shadowColor: Colors.transparent,
      constraints: BoxConstraints(
        minWidth: MediaQuery.of(context).size.width - 56,
        maxWidth: MediaQuery.of(context).size.width - 56,
      ),
      color: context.colors.dropdownMenuBackground,
      onOpened: () => isAssetPickerExpanded.value = true,
      onCanceled: () => isAssetPickerExpanded.value = false,
      onSelected: (index) {
        isAssetPickerExpanded.value = false;
        ref
            .read(topUpInputStateProvider.notifier)
            .selectAsset(input.availableAssets[index]);
      },
      itemBuilder: (context) => input.availableAssets
          .mapIndexed((index, asset) => PopupMenuItem(
                value: index,
                padding: index == 0
                    ? const EdgeInsets.only(top: 16)
                    : EdgeInsets.zero,
                child: AssetSelectionDropDownItem(asset),
              ))
          .toList(),
      child: BoxShadowContainer(
        bordered: true,
        color: context.colors.dropdownMenuBackground,
        borderColor: isAssetPickerExpanded.value
            ? context.colorScheme.primary
            : context.colors.onBackground,
        borderRadius: BorderRadius.circular(9),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 18,
        ),
        child: Row(
          children: [
            const SizedBox(width: 6),
            //ANCHOR - Asset Logo
            AssetIcon(
              assetId: input.asset.isLBTC ? kLayer2BitcoinId : input.asset.id,
              assetLogoUrl: input.asset.logoUrl,
              size: 28,
            ),
            const SizedBox(width: 12),
            //ANCHOR - Asset Name
            Text(
              input.asset.name,
              style: TextStyle(
                fontSize: 16,
                color: context.colors.onBackground,
                fontFamily: UiFontFamily.inter,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            //ANCHOR - Expand Icon
            Icon(
              Icons.expand_more,
              size: 20,
              color: context.colorScheme.onSurface,
            ),
          ],
        ),
      ),
    );
  }
}
