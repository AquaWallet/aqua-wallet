import 'package:aqua/features/note/note.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

const maxNoteLength = 3000;

class AddNoteScreen extends HookConsumerWidget {
  static const routeName = '/addNoteScreen';

  const AddNoteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();

    ref.listen(
      addNotePopProvider,
      (_, result) {
        Navigator.of(context).pop(result);
      },
    );

    return Scaffold(
      appBar: AquaAppBar(
        title: AppLocalizations.of(context)!.addNoteScreenTitle,
        showActionButton: false,
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          padding: EdgeInsets.only(bottom: 66.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              //ANCHOR - Input
              BoxShadowContainer(
                margin: EdgeInsets.only(top: 32.h),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                constraints: BoxConstraints(minHeight: 140.h),
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
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    hintText: AppLocalizations.of(context)!.addNoteScreenHint,
                    hintStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  onChanged: (text) {
                    ref.read(addNoteProvider).updateText(text);
                  },
                  onSubmitted: (text) =>
                      ref.read(addNoteProvider).updateText(text),
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
              SizedBox(
                width: double.maxFinite,
                child: BoxShadowElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    Future.delayed(const Duration(milliseconds: 200), () {
                      Navigator.of(context).pop(controller.text);
                    });
                  },
                  child: Text(
                    AppLocalizations.of(context)!.addNoteScreenSaveButton,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
