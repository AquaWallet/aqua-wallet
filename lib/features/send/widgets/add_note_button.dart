import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class AddNoteButton extends ConsumerWidget {
  const AddNoteButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return BoxShadowElevatedButton(
      onPressed: () async {
        // final note = await context.push(AddNoteScreen.routeName) as String?;
        //TODO: Move note state to [SendAssetInputStateNotifier]
      },
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      background: Theme.of(context).colorScheme.surface,
      foreground: Theme.of(context).colors.onBackground,
      side: !darkMode
          ? BorderSide(
              color: Theme.of(context).colors.roundedButtonOutlineColor,
              width: 1.0,
            )
          : null,
      child: Row(
        children: [
          //ANCHOR - Icon
          SvgPicture.asset(
            Svgs.addNote,
            width: 16.0,
            height: 16.0,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colors.background,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 14.0),
          //ANCHOR - Label
          Expanded(
            child: Text(
              context.loc.addNotes,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}
