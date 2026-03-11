import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/settings/language/language.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class LanguageSettings extends HookConsumerWidget {
  const LanguageSettings({
    required this.loc,
    required this.aquaColors,
    required this.currentLang,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;
  final Language currentLang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref
        .watch(languageProvider(context).select((p) => p.supportedLanguages));

    return OutlineContainer(
      aquaColors: aquaColors,
      child: ListView.separated(
        shrinkWrap: true,
        itemBuilder: (context, index) {
          final language = languages[index];
          final isCurrentRegion =
              language.languageCode == currentLang.languageCode;
          return AquaListItem(
            colors: aquaColors,

            ///TODO: pull flags from somewhere for langages
            // iconLeading: CountryFlag(
            //   svgAsset: region.flagSvg,
            //   height: 24,
            //   width: 24,
            // ),
            ///TODO: language names need to be pulled from somwhere
            title: language.languageCode,
            titleColor: aquaColors.textPrimary,
            iconTrailing: AquaRadio<bool>.small(
              value: isCurrentRegion,
              groupValue: true,
              colors: context.aquaColors,
            ),
            onTap: () {
              ref.read(languageProvider(context)).setCurrentLanguage(language);
            },
          );
        },
        separatorBuilder: (context, index) => const Divider(height: 0),
        itemCount: languages.length,
      ),
    );
  }
}
