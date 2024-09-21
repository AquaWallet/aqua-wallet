import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

import 'watch_only.dart';

class WatchOnlyListScreen extends HookConsumerWidget {
  static const routeName = '/watchOnlyListScreen';

  const WatchOnlyListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(watchOnlyProvider);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.watchOnlyScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 32.h),
            Text(
              context.loc.watchOnlyScreenSubtitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 12.h),
            Text(
              context.loc.watchOnlyScreenDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 32.h),
            Expanded(
              child: wallets.when(
                data: (wallets) {
                  return ListView.separated(
                    itemCount: wallets.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => SizedBox(height: 16.h),
                    itemBuilder: (_, index) {
                      final wallet = wallets[index];
                      return WatchOnlyListItem(
                        key: ValueKey(wallet.subaccount.pointer),
                        wallet: wallet,
                        onTap: () => _showWatchOnlyDetails(context, wallet),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
              ),
            ),
            SizedBox(height: kBottomPadding),
          ],
        ),
      ),
    );
  }

  void _showWatchOnlyDetails(BuildContext context, WatchOnlyWallet wallet) {
    Navigator.of(context).pushNamed(
      WatchOnlyDetailScreen.routeName,
      arguments: wallet,
    );
  }
}

class WatchOnlyListItem extends StatelessWidget {
  final WatchOnlyWallet wallet;
  final VoidCallback onTap;

  const WatchOnlyListItem({
    super.key,
    required this.wallet,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 8.w, top: 8.h, bottom: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.networkType.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8.h),
                    Text(wallet.subaccount.type?.displayName ?? '',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
            Icon(
              Icons.qr_code,
              size: 32.r,
            ),
          ],
        ),
      ),
    );
  }
}
