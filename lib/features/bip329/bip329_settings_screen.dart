import 'package:aqua/config/config.dart';
import 'package:aqua/features/bip329/bip329_export_provider.dart';
import 'package:aqua/features/bip329/bip329_import_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/gen/assets.gen.dart';

class NotesSettingsScreen extends HookConsumerWidget {
  static const routeName = '/notesSettingsScreen';

  const NotesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isNotesExportAvailable =
        ref.watch(bip329ExportNotifierProvider).asData?.value ?? false;

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.notesSettingsScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (isNotesExportAvailable) ...[
            const SizedBox(height: 32.0),
            Text(
              context.loc.notesSettingsScreenExportTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12.0),
            Text(
              context.loc.notesSettingsScreenExportTip,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32.0),
            InkWell(
                onTap: () =>
                    ref.read(bip329ExportNotifierProvider.notifier).exportNotes(
                          sharePositionOrigin: context.sharePositionOrigin,
                        ),
                child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Row(children: [
                      Text(context.loc.notesSettingsScreenExportButton)
                    ]))),
          ],
          const SizedBox(height: 32.0),
          Text(
            context.loc.notesSettingsScreenImportTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12.0),
          Text(
            context.loc.notesSettingsScreenImportTip,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32.0),
          InkWell(
              onTap: () async {
                final importedCount = await ref
                    .read(bip329ImportNotifierProvider.notifier)
                    .importNotes();
                if (!context.mounted) return;
                showGeneralDialog(
                    context: context,
                    pageBuilder: (_, __, ___) => PopScope(
                        canPop: true,
                        child: Scaffold(
                            body: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                              Expanded(
                                  child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    importedCount > 0
                                        ? UiAssets.checkSuccess.svg(
                                            width: 97.0,
                                          )
                                        : AquaUiAssets.svgs.statusWarning.svg(
                                            width: 97.0,
                                          ),
                                    const SizedBox(height: 40),
                                    Text(importedCount > 0
                                        ? context.loc
                                            .notesSettingsScreenImportSuccessMessage
                                        : context.loc
                                            .notesSettingsScreenImportNoMatches),
                                  ],
                                ),
                              )),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    child: Text(context.loc.ok),
                                    onPressed: () {
                                      context.pop();
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 66.0),
                            ]))));
              },
              child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(children: [
                    Text(context.loc.notesSettingsScreenImportButton)
                  ]))),
        ]),
      ),
    );
  }
}
