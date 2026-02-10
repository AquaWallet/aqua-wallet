import 'package:aqua/common/widgets/sliver_grid_delegate.dart';
import 'package:aqua/features/auth/auth_wrapper.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class WalletBackupConfirmationContent extends ConsumerWidget {
  const WalletBackupConfirmationContent({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selections =
        ref.watch(selectionStateNotifierProvider).where((e) => e != null);
    final isFilled = selections.length == 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Expanded(
          child: _SectionsContainerWidget(),
        ),
        const SizedBox(height: 16.0),
        AquaButton.primary(
          text: context.loc.backupConfirmationButton,
          onPressed: !isFilled
              ? null
              : () => ref.read(walletBackupConfirmationProvider).confirm(),
        ),
        const SizedBox(height: 16.0),
        AquaButton.secondary(
          text: context.loc.backupLater,
          onPressed: () => context.go(AuthWrapper.routeName),
        ),
        const SizedBox(height: 66.0),
      ],
    );
  }
}

class _SectionsContainerWidget extends ConsumerWidget {
  const _SectionsContainerWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sectionsAsyncValue = ref.watch(sectionsProvider);

    return sectionsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Text('Error: $err'),
      data: (sections) => _SectionsListWidget(sections: sections),
    );
  }
}

class _SectionsListWidget extends StatelessWidget {
  const _SectionsListWidget({
    required this.sections,
  });

  final List<Section> sections;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 18.0),
      itemCount: sections.length,
      itemBuilder: (context, index) => _SectionWidget(section: sections[index]),
      separatorBuilder: (context, _) => const SizedBox(height: 24.0),
    );
  }
}

class _SectionWidget extends ConsumerWidget {
  const _SectionWidget({
    required this.section,
  });

  final Section section;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex =
        ref.watch(selectionStateNotifierProvider)[section.index];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.loc.backupConfirmationSelect('${section.wordToSelect}'),
          style: AquaTypography.body1SemiBold.copyWith(
            color: context.aquaColors.textPrimary,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SizedBox(
            height: 34.0,
            child: GridView.builder(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                crossAxisCount: 3,
                mainAxisSpacing: 24.0,
                crossAxisSpacing: 16.0,
                height: 34.0,
              ),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: section.words.length,
              itemBuilder: (context, index) => _SectionWordWidget(
                word: section.words[index],
                section: section.index,
                selected: selectedIndex != null && index == selectedIndex % 3,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionWordWidget extends ConsumerWidget {
  const _SectionWordWidget({
    required this.word,
    required this.section,
    required this.selected,
  });

  final SectionWord word;
  final int section;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.aquaColors;
    return ChoiceChip(
      labelPadding: EdgeInsets.zero,
      backgroundColor: colors.accentBrandTransparent,
      selectedColor: colors.accentBrand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      label: Center(
        child: Text(
          word.title,
          style: AquaTypography.body2SemiBold.copyWith(
            color: selected ? colors.textInverse : colors.accentBrand,
          ),
        ),
      ),
      selected: selected,
      onSelected: (bool newValue) {
        ref
            .read(selectionStateNotifierProvider.notifier)
            .select(section, word.index);
      },
    );
  }
}
