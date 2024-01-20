import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class AddNoteButton extends ConsumerWidget {
  const AddNoteButton({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BoxShadowElevatedButton(
      background: Theme.of(context).colors.inputBackground,
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      onPressed: () async {
        // final note = await Navigator.of(context)
        //     .pushNamed(AddNoteScreen.routeName) as String?;
        // ref.read(noteProvider.notifier).state = note;
      },
      child: Row(
        children: [
          //ANCHOR - Icon
          SvgPicture.asset(Svgs.addNote,
              width: 16.r,
              height: 16.r,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onBackground, BlendMode.srcIn)),
          SizedBox(width: 14.w),
          //ANCHOR - Label
          Expanded(
            child: Text(
              AppLocalizations.of(context)!.receiveAssetScreenAddNotes,
            ),
          ),
        ],
      ),
    );
  }
}
