import 'package:aqua/common/widgets/tab_switch_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddressTypeTabBar extends HookConsumerWidget {
  const AddressTypeTabBar({
    super.key,
    required this.onTabChange,
  });

  final Function(int) onTabChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabSwitchView(
      labels: [
        AppLocalizations.of(context)!.receiveAddressChipsUsed,
        AppLocalizations.of(context)!.receiveAddressChipsAll,
      ],
      onChange: onTabChange,
    );
  }
}
