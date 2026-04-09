import 'dart:convert';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:aqua/utils/utils.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DebugWalletAuthScreen extends HookConsumerWidget {
  const DebugWalletAuthScreen({super.key});

  static const routeName = '/debugWalletAuthScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletsAsync = ref.watch(storedWalletsProvider);
    final showFullToken = useState(false);

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.walletAuthDebug,
        showBackButton: true,
        showActionButton: false,
      ),
      body: walletsAsync.when(
        data: (walletState) => Column(
          children: [
            SwitchListTile(
              title: Text(context.loc.showFullToken),
              value: showFullToken.value,
              onChanged: (v) => showFullToken.value = v,
            ),
            Expanded(
              child: ListView.builder(
                itemCount: walletState.wallets.length,
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final wallet = walletState.wallets[index];
                  final profile = wallet.profileResponse;
                  final rawToken = wallet.authToken?.access;
                  final tokenDisplay = rawToken == null
                      ? '—'
                      : showFullToken.value
                          ? rawToken
                          : sha256
                              .convert(utf8.encode(rawToken))
                              .toString()
                              .substring(0, 12);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(wallet.name,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          _DebugInfoRow(
                              label: 'Email', value: profile?.email ?? '—'),
                          _DebugInfoRow(
                              label: 'User ID', value: profile?.id ?? '—'),
                          _DebugInfoRow(label: 'Token', value: tokenDisplay),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _DebugInfoRow extends StatelessWidget {
  const _DebugInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 64,
              child:
                  Text('$label:', style: Theme.of(context).textTheme.bodySmall),
            ),
            Expanded(
              child: SelectableText(value,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      );
}
