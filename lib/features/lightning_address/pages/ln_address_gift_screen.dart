import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/lightning_address/pages/ln_address_gift_opened_screen.dart';
import 'package:aqua/features/lightning_address/providers/lightning_address_provider.dart';
import 'package:aqua/features/lightning_address/providers/ln_address_registration_provider.dart';
import 'package:aqua/features/lightning_address/widgets/ln_address_gift_content.dart';
import 'package:aqua/features/receive/models/receive_arguments.dart';
import 'package:aqua/features/receive/pages/receive_asset_screen.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class LnAddressGiftScreen extends ConsumerWidget {
  static const routeName = '/lnAddressGiftScreen';

  const LnAddressGiftScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletId = ref.watch(currentWalletIdSyncProvider);
    final authAsync = ref.watch(jan3AuthProvider(walletId));
    final lnAddressState = ref.watch(lightningAddressProvider);
    final canPop = !lnAddressState.shouldPromptGiftOpen;

    if (authAsync.isLoading) {
      return DesignRevampScaffold(
        appBar: AquaTopAppBar(
          title: context.loc.lnAddressGiftTitle,
          colors: context.aquaColors,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (lnAddressState.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.pushReplacement(
            ReceiveAssetScreen.routeName,
            extra: ReceiveArguments.fromAsset(Asset.lightning()),
          );
        }
      });
      return DesignRevampScaffold(
        appBar: AquaTopAppBar(
          title: context.loc.lnAddressGiftTitle,
          colors: context.aquaColors,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: canPop,
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          title: context.loc.lnAddressGiftTitle,
          colors: context.aquaColors,
          showBackButton: canPop,
          onBackPressed: canPop ? () => context.pop() : null,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: LnAddressGiftContent(
              onOpenBox: () {
                ref.read(lnReceiveModeProvider.notifier).setAddressMode();
                ref
                    .read(lnAddressRegistrationProvider.notifier)
                    .activate()
                    .ignore();
                context.pushReplacement(LnAddressGiftOpenedScreen.routeName);
              },
              onLater: canPop ? () => context.pop() : null,
            ),
          ),
        ),
      ),
    );
  }
}
