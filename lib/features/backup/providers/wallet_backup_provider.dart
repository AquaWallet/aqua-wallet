import 'dart:math';

import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/secure_storage_provider.dart';
import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';

final recoveryPhraseWordsProvider =
    FutureProvider.autoDispose<List<String>>((ref) async {
  final (mnemonic, err) =
      await ref.read(secureStorageProvider).get(StorageKeys.mnemonic);
  if (err != null || mnemonic == null) {
    return [];
  }

  return mnemonic.split(' ');
});

final _selectedWordsIndicesProvider = Provider.autoDispose<List<int>>((ref) {
  return List.generate(4, (index) => index * 3 + Random().nextInt(3));
});

final _selectedWordsInsertionIndicesProvider =
    Provider.autoDispose<List<int>>((ref) {
  return List.generate(4, (index) => index * 3 + Random().nextInt(3));
});

final _confirmationWordsProvider =
    FutureProvider.autoDispose<List<String>?>((ref) async {
  final recoveryPhraseWords =
      await ref.watch(recoveryPhraseWordsProvider.future);
  final confirmationRandomWords =
      await ref.watch(liquidProvider).generateMnemonic12();

  final selectedWordsIndices = ref.watch(_selectedWordsIndicesProvider);
  final recoveryPhraseWordsSelectedForCheck =
      selectedWordsIndices.map((index) => recoveryPhraseWords[index]).toList();

  final selectedWordsInsertionIndices =
      ref.watch(_selectedWordsInsertionIndicesProvider);

  for (var i = 0; i < recoveryPhraseWordsSelectedForCheck.length; i++) {
    final recoveryPhraseWord = recoveryPhraseWordsSelectedForCheck[i];
    final randomInsertionIndex = selectedWordsInsertionIndices[i];
    confirmationRandomWords?[randomInsertionIndex] = recoveryPhraseWord;
  }

  return confirmationRandomWords;
});

final selectionStateNotifierProvider =
    StateNotifierProvider.autoDispose<_SelectionStateNotifier, List<int?>>(
        (ref) {
  return _SelectionStateNotifier([null, null, null, null]);
});

class _SelectionStateNotifier extends StateNotifier<List<int?>> {
  _SelectionStateNotifier([List<int?>? initialSelections])
      : super(initialSelections ?? []);

  void select(int section, int index) {
    final newState = List<int?>.from(state);
    newState[section] = index;
    state = newState;
  }
}

final sectionsProvider = FutureProvider.autoDispose<List<Section>>((ref) async {
  final selectionWords = await ref.watch(_confirmationWordsProvider.future);
  final selectedWordsIndices = ref.watch(_selectedWordsIndicesProvider);

  final sections =
      List.generate(4, (sectionIndex) => sectionIndex).map((sectionIndex) {
    final words = List.generate(3, (rowIndex) => sectionIndex * 3 + rowIndex)
        .map((wordIndex) {
      final title = selectionWords?[wordIndex];
      return SectionWord(title: title ?? '', index: wordIndex);
    }).toList();

    final wordToSelect = selectedWordsIndices[sectionIndex] + 1;
    return Section(
      index: sectionIndex,
      wordToSelect: wordToSelect,
      words: words,
    );
  }).toList();

  return sections;
});

final walletBackupConfirmationProvider =
    Provider.autoDispose<_WalletBackupConfirmationProvider>(
        (ref) => _WalletBackupConfirmationProvider(ref));

class _WalletBackupConfirmationProvider {
  _WalletBackupConfirmationProvider(this._ref) {
    _ref.onDispose(() {
      _acceptInviteSubject.close();
      _confirmSubject.close();
      _showScreenshotWarningSubject.close();
    });
  }

  final AutoDisposeProviderRef _ref;

  final PublishSubject<void> _acceptInviteSubject = PublishSubject();
  void acceptInvite() {
    _acceptInviteSubject.add(null);
  }

  Stream<Object> _navigateToBackupPromptStream() =>
      _acceptInviteSubject.map((_) => Object());

  final PublishSubject<void> _confirmSubject = PublishSubject();
  late final Stream<AsyncValue<void>> _confirmationProcessingStream =
      _confirmSubject
          .switchMap((_) => Stream.value(null)
              .asyncMap((_) async {
                final selectedWordsInsertionIndices =
                    _ref.read(_selectedWordsInsertionIndicesProvider);
                final selectionState =
                    _ref.read(selectionStateNotifierProvider);
                if (!listEquals(
                    selectedWordsInsertionIndices, selectionState)) {
                  throw WalletBackupConfirmationUnableToConfirmException();
                }

                await _ref
                    .read(backupReminderProvider)
                    .setIsWalletBackedUp(true);
                return;
              })
              .map((_) => AsyncValue.data(_))
              .startWith(const AsyncValue.loading())
              .onErrorReturnWith(
                  (error, stacktrace) => AsyncValue.error(error, stacktrace)))
          .shareReplay(maxSize: 1);
  final PublishSubject<Object> _showScreenshotWarningSubject = PublishSubject();

  void confirm() {
    _confirmSubject.add(null);
  }

  void showScreenshotWarningDialog() {
    _showScreenshotWarningSubject.add(Object());
  }
}

final _walletBackupNavigateToBackupPromptStreamProvider =
    StreamProvider.autoDispose<Object>((ref) async* {
  yield* ref
      .watch(walletBackupConfirmationProvider)
      ._navigateToBackupPromptStream();
});

final walletBackupNavigateToBackupPromptProvider =
    Provider.autoDispose<Object?>((ref) {
  return ref
      .watch(_walletBackupNavigateToBackupPromptStreamProvider)
      .asData
      ?.value;
});

final _walletBackupConfirmationResultStreamProvider =
    StreamProvider.autoDispose<AsyncValue<void>>((ref) async* {
  yield* ref
      .watch(walletBackupConfirmationProvider)
      ._confirmationProcessingStream;
});

final walletBackupConfirmationResultProvider =
    Provider.autoDispose<AsyncValue<void>?>((ref) {
  return ref.watch(_walletBackupConfirmationResultStreamProvider).asData?.value;
});

final _walletShowScreenshotWarningDialogStreamProvider =
    StreamProvider.autoDispose<Object>((ref) async* {
  yield* ref
      .watch(walletBackupConfirmationProvider)
      ._showScreenshotWarningSubject;
});

final walletShowScreenshotWarningDialogProvider =
    Provider.autoDispose<Object?>((ref) {
  return ref
      .watch(_walletShowScreenshotWarningDialogStreamProvider)
      .asData
      ?.value;
});

class WalletBackupConfirmationUnableToConfirmException implements Exception {}

class WalletBackupConfirmationUnableToCreateException implements Exception {}

class Section {
  Section({
    required this.index,
    required this.wordToSelect,
    required this.words,
  });

  final int index;
  final int wordToSelect;
  final List<SectionWord> words;
}

class SectionWord {
  SectionWord({
    required this.index,
    required this.title,
  });

  final int index;
  final String title;
}
