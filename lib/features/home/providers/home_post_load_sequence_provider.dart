import 'package:aqua/features/shared/shared.dart';

/// One-time latch: post-load UI (wallet success sheet, Lightning welcome) is
/// scheduled once until the current wallet id changes (switch wallet / logout).
///
/// Single [AutoDisposeNotifier] avoids autoDispose **family** churn when
/// [storedWalletsProvider] / [currentWalletIdSyncProvider] update during load,
/// which could surface brief Riverpod/widget errors.
///
/// Further candidates to keep [HomeScreen] thin: backup-reminder navigation
/// ([backupReminderProvider] + [hasTransactedProvider]) and other pure
/// side-effect orchestration that still needs [BuildContext] for routes/modals.
final homePostLoadSequenceScheduledProvider =
    AutoDisposeNotifierProvider<HomePostLoadSequenceNotifier, bool>(
  HomePostLoadSequenceNotifier.new,
);

class HomePostLoadSequenceNotifier extends AutoDisposeNotifier<bool> {
  var _postFrameApplyPending = false;
  var _scheduleGeneration = 0;

  @override
  bool build() {
    ref.listen<String>(currentWalletIdSyncProvider, (previous, next) {
      if (previous != null && previous.isNotEmpty && previous != next) {
        _postFrameApplyPending = false;
        _scheduleGeneration++;
        state = false;
      }
    });
    return false;
  }

  void markScheduled() {
    if (ref.read(currentWalletIdSyncProvider).isEmpty) {
      return;
    }
    if (_postFrameApplyPending) {
      return;
    }
    _postFrameApplyPending = true;
    final gen = _scheduleGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFrameApplyPending = false;
      if (gen != _scheduleGeneration) {
        return;
      }
      state = true;
    });
  }
}
