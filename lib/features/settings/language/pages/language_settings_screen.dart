import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

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

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.languageSettingsTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
        onTitlePressed: () =>
            ref.read(featureUnlockTapCountProvider.notifier).increment(),
      ),
      body: SafeArea(
        child: SettingsSelectionList(
          label: currentLang.languageCode.toUpperCase(),
          items: languages
              .mapIndexed((index, item) => SettingsItem.create(item,
                  name: item.languageCode.toUpperCase(),
                  index: index,
                  length: languages.length))
              .toList(),
          itemBuilder: (context, item) {
            final language = item.object as Language;
            return SettingsListSelectionItem(
              content: Text(language.languageCode.toUpperCase()),
              position: item.position,
              onPressed: () => ref
                  .read(languageProvider(context))
                  .setCurrentLanguage(language),
            );
          },
        ),
      ),
    );
  }
}
