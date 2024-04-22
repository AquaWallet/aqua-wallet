import 'package:aqua/common/widgets/tab_switch_view_address_history.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AddressTypeTabBar extends HookConsumerWidget {
  const AddressTypeTabBar({
    super.key,
    required this.onTabChange,
  });

  final Function(int) onTabChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TabSwitchViewAddressHistory(
      labels: [
        context.loc.receiveAddressChipsUsed,
        context.loc.receiveAddressChipsAll,
      ],
      onChange: onTabChange,
    );
  }
}
