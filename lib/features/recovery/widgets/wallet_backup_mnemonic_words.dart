import 'package:aqua/common/widgets/sliver_grid_delegate.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/providers/wallet_backup_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class WalletBackupMnemonicWords extends HookConsumerWidget {
  const WalletBackupMnemonicWords({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wordsAsyncValue = ref.watch(recoveryPhraseWordsProvider);
    return wordsAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (words) => WalletBackupGridView(words: words),
    );
  }
}

class WalletBackupGridView extends ConsumerWidget {
  final List<String> words;
  const WalletBackupGridView({
    super.key,
    required this.words,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCountAndFixedHeight(
        crossAxisCount: 3,
        crossAxisSpacing: 15.w,
        mainAxisSpacing: 10.w,
        height: 38.h,
      ),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 12,
      itemBuilder: (_, index) => WalletBackupTile(
        isBotevMode: botevMode,
        number: '${index + 1}',
        title: words[index],
      ),
    );
  }
}

class WalletBackupTile extends StatelessWidget {
  const WalletBackupTile({
    super.key,
    required this.isBotevMode,
    required this.number,
    required this.title,
  });

  final bool isBotevMode;
  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 12.w, right: 8.w),
      decoration: isBotevMode
          ? BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12.r),
            )
          : BoxDecoration(
              gradient: AppStyle.gridItemGradient,
              borderRadius: BorderRadius.circular(12.r),
            ),
      child: Row(
        children: [
          SizedBox(
            width: 21.w,
            child: Text(
              number.padLeft(2, '0'),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontSize: 14.sp,
                  ),
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            title,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w400,
                  fontSize: 14.sp,
                  height: 1.0,
                ),
          ),
        ],
      ),
    );
  }
}
