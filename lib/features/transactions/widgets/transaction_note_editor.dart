import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/utils/utils.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/config/config.dart';

const maxLength = 200;

class TransactionNoteEditor extends HookConsumerWidget {
  const TransactionNoteEditor({
    super.key,
    required this.txHash,
    this.initialNote,
  });

  final String txHash;
  final String? initialNote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(text: initialNote);

    controller.addListener(() {
      if (controller.text.contains('\n')) {
        controller.text = controller.text.replaceAll('\n', '');
      }
    });

    final note = useValueListenable(controller);
    final focusNode = useFocusNode()..requestFocus();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 21.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 18.0),
          //ANCHOR - Title
          Text(
            context.loc.addNotes,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.0,
                ),
          ),
          const SizedBox(height: 8.0),
          //ANCHOR - Note Input
          Container(
            height: 100,
            decoration: Theme.of(context).solidBorderDecoration,
            child: TextField(
              minLines: null,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              focusNode: focusNode,
              controller: controller,
              inputFormatters: [LengthLimitingTextInputFormatter(maxLength)],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                hintText: context.loc.addNoteScreenHint,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text("${controller.text.length}/$maxLength",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 18.0),
          SizedBox(
            width: double.maxFinite,
            child: ElevatedButton(
              onPressed: note.text.trim() == initialNote?.trim()
                  ? null
                  : () async {
                      await ref
                          .read(transactionStorageProvider.notifier)
                          .updateTransactionNote(
                            txHash: txHash,
                            note: note.text.trim(),
                          );

                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
              child: Text(context.loc.save),
            ),
          )
        ],
      ),
    );
  }
}
