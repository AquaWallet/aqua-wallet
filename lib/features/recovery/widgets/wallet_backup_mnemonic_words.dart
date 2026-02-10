import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class WalletBackupMnemonicWords extends HookConsumerWidget {
  final bool isHidden;
  final String? walletId;

  const WalletBackupMnemonicWords({
    super.key,
    this.isHidden = false,
    this.walletId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsyncValue = ref.watch(recoveryPhraseWordsProvider(walletId));
    return wordsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (words) => WalletBackupView(words: words, isHidden: isHidden),
    );
  }
}

class WalletBackupView extends HookConsumerWidget {
  final List<String> words;
  final bool isHidden;

  const WalletBackupView({
    super.key,
    required this.words,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AquaCard(
      borderRadius: BorderRadius.circular(8),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: words.length,
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: context.aquaColors.surfaceBackground,
        ),
        itemBuilder: (context, index) {
          return AquaSeedInputField.readOnly(
            index: index + 1,
            text: isHidden ? '****' : words[index],
            colors: context.aquaColors,
          );
        },
      ),
    );
  }
}
