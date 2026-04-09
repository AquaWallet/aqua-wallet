import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class ContactSupportSideSheet extends StatelessWidget {
  const ContactSupportSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: 'Export Watch Only',
      showBackButton: false,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: AquaMarketplaceTile(
                title: 'Zendesk',
                subtitle: 'Contact Contact\nSupport for assistance',
                icon: UiAssets.assetIcons.zendeskLogo.svg(
                  height: 16,
                  width: 16,
                  colorFilter: ColorFilter.mode(
                    aquaColors.textPrimary,
                    BlendMode.srcIn,
                  ),
                ),
                colors: aquaColors,
                isEnabled: true,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: AquaMarketplaceTile(
                title: 'FAQ',
                subtitle: 'Find answers to\ncommon questions',

                ///TODO: change to appropriate icon
                icon: AquaIcon.caret(
                  size: 18,
                  color: aquaColors.textSecondary,
                ),
                colors: aquaColors,
                isEnabled: true,
                onTap: () {},
              ),
            ),
          ],
        )
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: ContactSupportSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}
