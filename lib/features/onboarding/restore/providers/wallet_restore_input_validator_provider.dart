import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';

final walletRestoreInputCompleteProvider = Provider.autoDispose<bool>((ref) {
  return List.generate(
    kMnemonicLength,
    (index) => ref.watch(fieldValueStreamProvider(index)),
  ).every((value) => value?.$1?.isNotEmpty ?? false);
});
