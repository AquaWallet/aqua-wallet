import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class LnReceiveModeSwitcher extends ConsumerWidget {
  const LnReceiveModeSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isInvoiceMode = ref.watch(lnReceiveModeProvider);

    return AquaChip.accent(
      colors: context.aquaColors,
      label: isInvoiceMode
          ? context.loc.receiveLightningSwitchToAddress
          : context.loc.receiveLightningSwitchToInvoice,
      leadingIcon: AquaIcon.switching(
        size: 16,
        color: context.aquaColors.accentBrand,
      ),
      onTap: () {
        if (isInvoiceMode) {
          final lnAddress = ref.read(lightningAddressProvider);
          if (lnAddress == null || !lnAddress.isToggled) {
            ref.read(lnReceiveModeProvider.notifier).setAddressMode();
            context.push(LnAddressGiftScreen.routeName, extra: true);
            return;
          }
        }
        ref.read(lnReceiveModeProvider.notifier).toggle();
      },
    );
  }
}
