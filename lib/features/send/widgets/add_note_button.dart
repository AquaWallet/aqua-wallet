import 'package:aqua/config/config.dart';
import 'package:aqua/features/note/note.dart';
import 'package:aqua/features/send/providers/send_asset_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class AddNoteButton extends ConsumerWidget {
  const AddNoteButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return BoxShadowElevatedButton(
      onPressed: () async {
        final note = await Navigator.of(context)
            .pushNamed(AddNoteScreen.routeName) as String?;
        ref.read(noteProvider.notifier).state = note;
      },
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      background: Theme.of(context).colorScheme.surface,
      foreground: Theme.of(context).colorScheme.onBackground,
      side: !darkMode
          ? BorderSide(
              color: Theme.of(context).colors.roundedButtonOutlineColor,
              width: 1.w,
            )
          : null,
      child: Row(
        children: [
          //ANCHOR - Icon
          SvgPicture.asset(
            Svgs.addNote,
            width: 16.r,
            height: 16.r,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.onBackground,
              BlendMode.srcIn,
            ),
          ),
          SizedBox(width: 14.w),
          //ANCHOR - Label
          Expanded(
            child: Text(
              context.loc.receiveAssetScreenAddNotes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
