import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32.0),
            Text(
              context.loc.watchOnlyScreenSubtitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12.0),
            Text(
              context.loc.watchOnlyScreenDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32.0),
            Expanded(
              child: wallets.when(
                data: (wallets) {
                  return ListView.separated(
                    itemCount: wallets.length,
                    physics: const BouncingScrollPhysics(),
                    separatorBuilder: (_, __) => const SizedBox(height: 16.0),
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
            const SizedBox(height: kBottomPadding),
          ],
        ),
      ),
    );
  }

  void _showWatchOnlyDetails(BuildContext context, Subaccount wallet) {
    context.push(
      WatchOnlyDetailScreen.routeName,
      extra: wallet,
    );
  }
}

class WatchOnlyListItem extends StatelessWidget {
  final Subaccount wallet;
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
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, top: 8.0, bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallet.networkType.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8.0),
                    Text(wallet.subaccount.type?.typeName ?? '',
                        style: Theme.of(context).textTheme.labelMedium),
                  ],
                ),
              ),
            ),
            const Icon(
              Icons.qr_code,
              size: 32.0,
            ),
          ],
        ),
      ),
    );
  }
}
