import 'package:aqua/data/models/focus_action.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

//TODO - Remove RxDart dependency

final _walletFocusActionProvider =
    Provider.autoDispose(WalletFocusActionProvider.new);

final _focusActionStreamProvider =
    StreamProvider.autoDispose<FocusAction>((ref) async* {
  final focusActionStream =
      ref.watch(_walletFocusActionProvider).focusActionStream;
  yield* focusActionStream;
});

final focusActionProvider = Provider.autoDispose<FocusAction?>(
    (ref) => ref.watch(_focusActionStreamProvider).asData?.value);

class WalletFocusActionProvider {
  WalletFocusActionProvider(this.ref);
  final AutoDisposeProviderRef ref;

  // This stream determines whether to focus the next field or unfocus if last field
  late final Stream<FocusAction> focusActionStream = Rx.merge(List.generate(
    kMnemonicLength,
    (index) => ref
        .read(walletRestoreItemProvider(index))
        .fieldValueStream
        .map((value) => value?.$1)
        .switchMap<String>((value) =>
            value != null ? Stream.value(value) : const Stream.empty())
        .asyncMap((value) => index < 11
            ? ref
                .read(walletRestoreItemProvider(index + 1))
                .fieldValueStream
                .map((value) => value?.$1)
                .switchIfEmpty(Stream.value(null))
                .map((value) => value == null || value.isEmpty
                    ? FocusAction.next()
                    : FocusAction.clear())
                .first
            : Future.value(FocusAction.clear())),
  ));
}
