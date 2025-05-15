import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../pages/pages.dart';
import '../providers/providers.dart';
import '../widgets/widgets.dart';

const _keyNavBarDemo = 'Nav Bar';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(prefsProvider).selectedTheme;
    final selectedIndex = useState(0);
    final demoItems = {
      _keyNavBarDemo: Center(
        child: AquaButton.utility(
          text: 'Open Nav Bar Demo',
          onPressed: () {
            Navigator.of(context).pushNamed(NavBarDemoPage.routeName);
          },
        ),
      ),
      'Transaction Summaries': const TransactionSummaryDemoPage(),
      'Header': const TopAppbarDemoPage(),
      'Numpad': const NumpadDemoPage(),
      'Asset Input': const AssetInputDemoPage(),
      'Textfield': const TextfieldDemoPage(),
      'Debit Card': const DebitCardDemoPage(),
      'Wallet Price & Balance': const WalletPriceBalanceDemoPage(),
      'Quick Actions': const QuickActionsDemoPage(),
      'Seed Phrase': const SeedPhraseDemoPage(),
      'Asset Selector': const AssetSelectorDemoPage(),
      'List Item': const ListItemDemoPage(),
      'Manage Assets Item': const ManageAssetsItemDemoPage(),
      'Transaction Items': const TransactionItemDemoPage(),
      'Address Item': const AddressItemDemoPage(),
      'Button': const ButtonDemoPage(),
      'Tile': const TileDemoPage(),
      'Modal Sheet': const ModalSheetDemoPage(),
      'Account Balance': const AccountBalanceDemoPage(),
      'Notification Item': const NotificationItemDemoPage(),
      'Account Item': const AccountItemDemoPage(),
      'Icon': const IconDemoPage(),
      'Tab, Chip & Tooltip': const TabChipTooltipDemoPage(),
      'Utility Item': const UtilityItemDemoPage(),
      'Surface': const SurfaceDemoPage(),
    };

    return Scaffold(
      appBar: const AquaAppBar(),
      backgroundColor: theme.colors.surfaceBackground,
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: demoItems.entries.indexed
                .map((e) => ListTile(
                      title: Text(e.$2.key),
                      onTap: () {
                        if (e.$2.key == _keyNavBarDemo) {
                          Navigator.of(context)
                              .pushNamed(NavBarDemoPage.routeName);
                          return;
                        }
                        selectedIndex.value = e.$1;
                        Navigator.pop(context);
                      },
                    ))
                .toList(),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: demoItems.values.elementAt(selectedIndex.value),
        ),
      ),
    );
  }
}
