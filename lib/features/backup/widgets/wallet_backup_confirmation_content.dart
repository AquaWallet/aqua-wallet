import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/sliver_grid_delegate.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

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
        SizedBox(height: 30.h),
        Text(
          context.loc.backupConfirmationTitle,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 21.sp,
                letterSpacing: .8,
              ),
        ),
        const Expanded(
          child: _SectionsContainerWidget(),
        ),
        SizedBox(height: 16.h),
        AquaElevatedButton(
          onPressed: !isFilled
              ? null
              : () => ref.read(walletBackupConfirmationProvider).confirm(),
          child: Text(context.loc.backupConfirmationButton),
        ),
        SizedBox(height: 64.h),
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
      padding: EdgeInsets.only(top: 18.h),
      itemCount: sections.length,
      itemBuilder: (context, index) => _SectionWidget(section: sections[index]),
      separatorBuilder: (context, _) => Container(height: 19.h),
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
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Padding(
          padding: EdgeInsets.only(top: 12.h),
          child: SizedBox(
            height: 48.h,
            child: GridView.builder(
              gridDelegate:
                  SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
                crossAxisCount: 3,
                mainAxisSpacing: 25.h,
                crossAxisSpacing: 15.w,
                height: 38.h,
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
    return ChoiceChip(
      labelPadding: EdgeInsets.zero,
      backgroundColor: !selected ? AquaColors.eerieBlack : null,
      selectedColor: AquaColors.blueGreen,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      label: Center(
        child: Text(word.title),
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
