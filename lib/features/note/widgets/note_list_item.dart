import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class NoteListItem extends StatelessWidget {
  const NoteListItem({
    super.key,
    required this.note,
    required this.onTap,
  });

  final String? note;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AquaListItem(
      onTap: onTap,
      title: note != null && note!.isNotEmpty ? note! : context.loc.addNote,
      iconLeading: AquaIcon.edit(
        color: context.aquaColors.textPrimary,
      ),
      iconTrailing: AquaIcon.chevronForward(
        size: 18,
        color: context.aquaColors.textSecondary,
      ),
    );
  }
}
