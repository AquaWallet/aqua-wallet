import 'package:aqua/features/note/note.dart';
import 'package:aqua/features/transactions/exceptions/transaction_exceptions.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class TransactionNoteListItem extends HookConsumerWidget {
  const TransactionNoteListItem({
    super.key,
    required this.txHash,
    required this.note,
  });

  final String txHash;
  final String? note;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onTap = useCallback(() async {
      final updatedNote = await AquaBottomSheet.show(
        context,
        content: AddNoteForm(note: note),
        colors: context.aquaColors,
      );
      if (updatedNote == note) {
        // this was cancel action
        return;
      }
      try {
        await ref
            .read(transactionStorageProvider.notifier)
            .updateTransactionNote(
              txHash: txHash,
              note: updatedNote,
            );
      } on TransactionNotFoundException {
        // Transaction exists in network but not in DB (e.g., restored wallet)
        // Create minimal record then add the note
        await ref
            .read(transactionStorageProvider.notifier)
            .findOrCreateTransaction(txHash: txHash);
        await ref
            .read(transactionStorageProvider.notifier)
            .updateTransactionNote(
              txHash: txHash,
              note: updatedNote,
            );
      }
      ref.invalidate(assetTransactionDetailsProvider);
    }, [note, txHash]);

    return NoteListItem(
      note: note,
      onTap: onTap,
    );
  }
}
