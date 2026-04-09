import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pinput/pinput.dart';
import 'package:ui_components/ui_components.dart';

const _kMaxNoteLength = 200;

class AddNoteForm extends HookWidget {
  const AddNoteForm({
    super.key,
    this.note,
  });

  final String? note;

  @override
  Widget build(BuildContext context) {
    final controller = useTextEditingController(text: note);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 45),
          //ANCHOR - Title
          GestureDetector(
            onLongPress: kDebugMode
                ? () => controller.setText(
                    'Iure doloremque consequuntur omnis suscipit iusto minus provident labore.')
                : null,
            child: AquaText.subtitleSemiBold(
              text: context.loc.addNote,
            ),
          ),
          const SizedBox(height: 24),
          //ANCHOR - Input
          AquaTextField(
            controller: controller,
            maxLength: _kMaxNoteLength,
            maxLines: 3,
            minLines: 3,
            label: context.loc.addNote,
            showCounter: true,
            forceFocus: true,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 24),
          //ANCHOR - Save Button
          AquaButton.primary(
            onPressed: () {
              FocusScope.of(context).unfocus();
              Future.delayed(
                const Duration(milliseconds: 200),
                () => context.pop(controller.text),
              );
            },
            text: context.loc.save,
          ),
          const SizedBox(height: 16),
          //ANCHOR - Cancel Button
          AquaButton.secondary(
            onPressed: () => context.pop(note),
            text: context.loc.cancel,
          ),
        ],
      ),
    );
  }
}
