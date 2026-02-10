import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class LanguageSettingsScreen extends HookConsumerWidget {
  static const routeName = '/languageSettingsScreen';
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languages = ref
        .watch(languageProvider(context).select((p) => p.supportedLanguages));
    final currentLang =
        ref.watch(languageProvider(context).select((p) => p.currentLanguage));

    ref.listen(featureUnlockTapCountProvider, (_, __) async {
      final enabled = await ref.read(prefsProvider).switchHiddenLanguages();
      final isHiddenLangSelected = !languages.contains(currentLang);
      Future.microtask(() async {
        //NOTE - Switch the current language to English if hidden languages have
        //been disabled and the current language is one of them.
        if (!enabled && isHiddenLangSelected) {
          ref
              .read(languageProvider(context))
              .setCurrentLanguage(languages.first);
        }
        if (enabled) {
          context.showSuccessSnackbar(
              context.loc.settingsScreenItemHiddenLanguageEnabled);
        } else {
          context.showErrorSnackbar(
              context.loc.settingsScreenItemHiddenLanguageDisabled);
        }
      });
    });

    return DesignRevampScaffold(
      extendBodyBehindAppBar: true,
      appBar: AquaTopAppBar(
        showBackButton: true,
        title: context.loc.language,
        colors: context.aquaColors,
        onTitlePressed: () =>
            ref.read(featureUnlockTapCountProvider.notifier).increment(),
      ),
      body: SettingsSelectionList(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          16 + MediaQuery.of(context).padding.bottom,
        ),
        items: languages
            .mapIndexed((index, item) => SettingsItem.create(item,
                name: item.languageCode.toUpperCase(),
                index: index,
                length: languages.length))
            .toList(),
        itemBuilder: (context, item) {
          final language = item.object as Language;

          return SettingsListSelectionItem<String>(
            icon: CountryFlag(
              svgAsset: language.region.flagSvg,
              width: 18,
              height: 18,
            ),
            title: language.originalLanguageName,
            subTitle: language.translatedLanguageName,
            onPressed: () => ref
                .read(languageProvider(context))
                .setCurrentLanguage(language),
            radioValue: language.languageCode,
            radioGroupValue: currentLang.languageCode,
            isRadioButton: true,
          );
        },
      ),
    );
  }
}
