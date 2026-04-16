import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/providers/stored_wallets_provider.dart';
import 'package:aqua/features/wallet/utils/bip32_utils.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LegacyWalletScreen extends HookConsumerWidget {
  const LegacyWalletScreen({super.key});

  static const routeName = '/legacyWalletScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = useState(false);
    final legacyInfoAsync = useFuture(
      useMemoized(() => _loadLegacyWalletInfo(ref), []),
    );

    return Scaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
        title: context.loc.settingsScreenItemLegacyWallet,
        showBackButton: true,
      ),
      body: legacyInfoAsync.connectionState == ConnectionState.waiting
          ? const Center(child: CircularProgressIndicator())
          : legacyInfoAsync.hasError
              ? const Center(
                  child: Text('Error loading wallet info'),
                )
              : legacyInfoAsync.data == null
                  ? Center(
                      child: Text(context
                          .loc.legacyWalletSettingsScreenNoWalletMessage),
                    )
                  : _buildDetails(context, legacyInfoAsync.data!, isVisible),
    );
  }

  Future<_LegacyInfo?> _loadLegacyWalletInfo(WidgetRef ref) async {
    final storage = ref.read(secureStorageProvider);
    final (legacyMnemonic, _) = await storage.get(StorageKeys.legacyMnemonic);

    if (legacyMnemonic == null) return null;

    final fingerprint = generateBip32Fingerprint(legacyMnemonic);
    final wallet =
        ref.read(storedWalletsProvider).valueOrNull?.getWalletById(fingerprint);

    return _LegacyInfo(
      fingerprint: fingerprint,
      name: wallet?.name,
      mnemonic: legacyMnemonic,
    );
  }

  Widget _buildDetails(
    BuildContext context,
    _LegacyInfo info,
    ValueNotifier<bool> isVisible,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Fingerprint
        _buildInfoRow(context.loc.legacyWalletSettingsScreenFingerprintTitle,
            info.fingerprint, context),
        const SizedBox(height: 16),

        // Name
        _buildInfoRow(context.loc.walletName, info.name ?? 'N/A', context),
        const SizedBox(height: 16),

        // Mnemonic with toggle
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  context.loc.seedPhraseTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: context.aquaColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: isVisible.value
                      ? AquaIcon.eyeOpen(
                          size: 20,
                          color: context.aquaColors.textSecondary,
                        )
                      : AquaIcon.eyeClose(
                          size: 20,
                          color: context.aquaColors.textSecondary,
                        ),
                  onPressed: () => isVisible.value = !isVisible.value,
                ),
              ],
            ),
            Text(
              isVisible.value ? info.mnemonic : '••••••••••••',
              style: TextStyle(
                color: context.aquaColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.aquaColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: context.aquaColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _LegacyInfo {
  final String fingerprint;
  final String? name;
  final String mnemonic;

  _LegacyInfo({
    required this.fingerprint,
    required this.name,
    required this.mnemonic,
  });
}
