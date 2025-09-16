import 'package:coin_cz/common/widgets/tab_switch_view_address_history.dart';
import 'package:coin_cz/utils/utils.dart';
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
        context.loc.usedAddresses,
        context.loc.receiveAddressChipsAll,
      ],
      onChange: onTabChange,
    );
  }
}
