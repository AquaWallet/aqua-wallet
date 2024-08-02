import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const maxNoteLength = 3000;

class AddNoteScreen extends HookConsumerWidget {
  static const routeName = '/addNoteScreen';

  const AddNoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final note = useValueListenable(controller);

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.addNoteScreenTitle,
        showActionButton: false,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              //ANCHOR - Input
              Container(
                margin: EdgeInsets.only(top: 32.h),
                constraints: BoxConstraints(minHeight: 140.h),
                decoration: Theme.of(context).solidBorderDecoration,
                child: TextField(
                  minLines: 6,
                  maxLines: 16,
                  maxLength: 3000,
                  controller: controller,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                  decoration: Theme.of(context).inputDecoration.copyWith(
                        border: Theme.of(context).inputBorder,
                        counterText: '',
                        hintText: context.loc.addNoteScreenHint,
                        hintStyle: Theme.of(context)
                            .textTheme
                            .labelLarge
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                ),
              ),
              //ANCHOR - Counter
              GestureDetector(
                onLongPress: kDebugMode
                    ? () => controller.text =
                        'Iure doloremque consequuntur omnis suscipit iusto minus provident labore.'
                    : null,
                child: Container(
                  alignment: Alignment.centerRight,
                  margin: EdgeInsets.only(top: 16.h),
                  child: Text(
                    '${controller.text.length}/$maxNoteLength',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
              const Spacer(),
              //ANCHOR - Button
              AquaElevatedButton(
                onPressed: note.text.isNotEmpty
                    ? () {
                        FocusScope.of(context).unfocus();
                        Future.delayed(
                          const Duration(milliseconds: 200),
                          () => Navigator.of(context).pop(controller.text),
                        );
                      }
                    : null,
                child: Text(
                  context.loc.addNoteScreenSaveButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
