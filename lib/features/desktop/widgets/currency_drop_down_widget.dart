import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class CurrencyDropDownWidget extends HookWidget {
  const CurrencyDropDownWidget(
      {super.key,
      required this.aquaColors,
      this.textBeforeCountryFlag,
      this.showDropDownIcon = true});

  final AquaColors aquaColors;
  final String? textBeforeCountryFlag;
  final bool showDropDownIcon;

  @override
  Widget build(BuildContext context) {
    final dropDownListKey = useMemoized(() => GlobalKey());
    return Card(
      key: dropDownListKey,
      elevation: 0,
      color: aquaColors.surfacePrimary,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(32),
      ),
      child: InkWell(
        onTap: showDropDownIcon
            ? () {
                ///TODO: opens drop down with available currencies
                AquaDropDown.show(
                    context: context,
                    anchor: dropDownListKey.currentContext!.findRenderObject(),
                    containerWidth: widthOfCurrencySelectionDropDown,
                    containerHeight: 284,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AquaListItem(
                          iconLeading: CountryFlag(
                            svgAsset: UiAssets.flags.unitedStatesOfAmerica.path,
                            height: 24,
                            width: 24,
                          ),
                          title: 'United States Dollar (\$ USD)',
                          colors: aquaColors,
                          onTap: () {
                            Navigator.pop(context);
                          },
                          iconTrailing: AquaRadio<bool>.small(
                            groupValue: true,
                            value: true,
                            colors: context.aquaColors,
                          ),
                        ),
                        AquaListItem(
                            iconLeading: CountryFlag(
                              svgAsset: UiAssets.flags.europeanUnion.path,
                              height: 24,
                              width: 24,
                            ),
                            title: 'Euro (€ EUR)',
                            colors: aquaColors,
                            onTap: () {
                              Navigator.pop(context);
                            },
                            iconTrailing: AquaRadio<bool>.small(
                              groupValue: true,
                              value: false,
                              colors: context.aquaColors,
                            )),
                        AquaListItem(
                            iconLeading: CountryFlag(
                              svgAsset: UiAssets.flags.canada.path,
                              height: 24,
                              width: 24,
                            ),
                            title: 'Canadian Dollar (\$ CAD)',
                            colors: aquaColors,
                            onTap: () {
                              Navigator.pop(context);
                            },
                            iconTrailing: AquaRadio<bool>.small(
                              groupValue: true,
                              value: false,
                              colors: context.aquaColors,
                            )),
                        AquaListItem(
                            iconLeading: CountryFlag(
                              svgAsset: UiAssets.flags.england.path,
                              height: 24,
                              width: 24,
                            ),
                            title: 'British Pound Sterling (£ GBP)',
                            colors: aquaColors,
                            onTap: () {
                              Navigator.pop(context);
                            },
                            iconTrailing: AquaRadio<bool>.small(
                              groupValue: true,
                              value: false,
                              colors: context.aquaColors,
                            )),
                        AquaListItem(
                            iconLeading: CountryFlag(
                              svgAsset: UiAssets.flags.switzerland.path,
                              height: 24,
                              width: 24,
                            ),
                            title: 'Swiss Franc (CHF)',
                            colors: aquaColors,
                            onTap: () {
                              Navigator.pop(context);
                            },
                            iconTrailing: AquaRadio<bool>.small(
                              groupValue: true,
                              value: false,
                              colors: context.aquaColors,
                            )),
                      ],
                    ),
                    colors: aquaColors);
              }
            : null,
        borderRadius: BorderRadius.circular(32),
        child: SizedBox(
          height: 24,
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (textBeforeCountryFlag != null) ...[
                  AquaText.body2SemiBold(
                    text: textBeforeCountryFlag!,
                    color: aquaColors.textPrimary,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: VerticalDivider(
                      width: 0,
                      indent: 4,
                      endIndent: 4,
                    ),
                  ),
                ],
                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: UiAssets.flags.unitedStatesOfAmerica.svg(width: 16),
                ),
                const SizedBox(width: 8),
                AquaText.body2SemiBold(
                  text: 'USD',
                  color: aquaColors.textPrimary,
                ),
                if (showDropDownIcon) ...[
                  const SizedBox(width: 2),
                  AquaIcon.caret(
                    size: 16,
                    color: aquaColors.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
