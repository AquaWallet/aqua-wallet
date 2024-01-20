import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rxdart/rxdart.dart';

final welcomeProvider =
    Provider.autoDispose<_WelcomeProvider>((ref) => _WelcomeProvider(ref));

class _WelcomeProvider {
  _WelcomeProvider(this._ref) {
    _ref.onDispose(() {
      _showWalletPromptDialogSubject.close();
    });
  }

  final AutoDisposeProviderRef _ref;

  final PublishSubject<void> _showWalletPromptDialogSubject = PublishSubject();
  void showWalletPromptDialog() {
    _showWalletPromptDialogSubject.add(null);
  }

  Stream<Object> _showWalletPromptDialogStream() =>
      _showWalletPromptDialogSubject.map((event) => Object());
}

final _welcomeShowWalletPromptDialogStreamProvider =
    StreamProvider.autoDispose<Object>((ref) async* {
  yield* ref.watch(welcomeProvider)._showWalletPromptDialogStream();
});

final welcomeShowWalletPromptDialogProvider =
    Provider.autoDispose<Object?>((ref) {
  return ref.watch(_welcomeShowWalletPromptDialogStreamProvider).asData?.value;
});
