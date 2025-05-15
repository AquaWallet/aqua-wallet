import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';
import 'package:ui_components_playground/shared/shared.dart';

import '../../providers/providers.dart';
import '../../widgets/widgets.dart';

const _kDrawerWidth = 268.0;
const _lorem = 'lorem ipsum dolor sit amet consectetur adipiscing elit sed do';

class NavBarDemoPage extends HookConsumerWidget {
  const NavBarDemoPage({super.key});

  static const routeName = '/nav-bar-demo';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedBottomNavIndex = useState(0);
    final selectedDrawerNavIndex = useState(0);
    final theme = ref.watch(prefsProvider).selectedTheme;
    final items1 = [
      (label: 'Wallet', icon: AquaIcon.wallet),
      (label: 'Marketplace', icon: AquaIcon.marketplace),
      (label: 'Settings', icon: AquaIcon.settings),
    ];
    final items2 = [
      (label: 'Receive', icon: AquaIcon.arrowDownLeft),
      (label: 'Send', icon: AquaIcon.arrowUpRight),
      (label: 'Scan', icon: AquaIcon.scan),
    ];
    final items3 = [
      (label: 'Share', icon: AquaIcon.share),
      (label: 'Copy Address', icon: AquaIcon.copy),
    ];
    final items4 = [
      (label: 'Scan', icon: AquaIcon.scan),
      (label: 'Paste', icon: AquaIcon.paste),
    ];

    return Scaffold(
      appBar: const AquaAppBar(),
      drawer: Drawer(
        width: _kDrawerWidth,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: AquaNavDrawer(
          sections: [
            AquaNavDrawerSection(
              title: 'Digital Wallets',
              colors: theme.colors,
              itemCount: 2,
              itemBuilder: (context, index) => AquaNavDrawerItem(
                label: 'Wallet ${index + 1}',
                icon: AquaIcon.wallet,
                isSelected: selectedDrawerNavIndex.value == index,
                colors: theme.colors,
                onTap: () {
                  selectedDrawerNavIndex.value = index;
                  AquaTooltip.show(
                    context,
                    message: 'Wallet ${index + 1} tapped',
                  );
                },
              ),
            ),
            AquaNavDrawerSection(
              title: 'Hardware Wallets',
              colors: theme.colors,
              itemCount: 2,
              itemBuilder: (context, index) => AquaNavDrawerItem(
                label: 'HW Wallet ${index + 1}',
                icon: AquaIcon.hardwareWallet,
                isSelected: selectedDrawerNavIndex.value == 2 + index,
                colors: theme.colors,
                onTap: () {
                  selectedDrawerNavIndex.value = 2 + index;
                  AquaTooltip.show(
                    context,
                    message: 'HW Wallet ${index + 1} tapped',
                  );
                },
              ),
            ),
          ],
          footer: AquaNavDrawerFooterButton(
            label: 'Add Wallet',
            icon: AquaIcon.plus,
            onTap: () => AquaTooltip.show(
              context,
              message: 'Add Wallet tapped',
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              AquaNavHeader(
                title: 'Wallet',
                onReceiveTap: () {},
                onSendTap: () {},
                onSwapTap: () {},
                onMarketplaceTap: () {},
                onRegionTap: () {},
                onUserTap: () {},
                onSettingsTap: () {},
                colors: theme.colors,
              ),
              const SizedBox(height: 32),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 375),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.all(16),
                            child: AquaFloatingActionButton(
                              icon: AquaIcon.swap,
                              onTap: () => AquaTooltip.show(
                                context,
                                message: 'FAB tapped',
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          AquaNavBar(
                            colors: theme.colors,
                            itemCount: items1.length,
                            itemBuilder: (context, index) => AquaNavBarItem(
                              onTap: () {
                                if (selectedBottomNavIndex.value != index) {
                                  selectedBottomNavIndex.value = index;
                                  AquaTooltip.show(
                                    context,
                                    message: '${items1[index].label} selected',
                                  );
                                }
                              },
                              isSelected: selectedBottomNavIndex.value == index,
                              icon: items1[index].icon,
                              label: items1[index].label,
                              colors: theme.colors,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AquaNavBar(
                            colors: theme.colors,
                            itemCount: items2.length,
                            itemBuilder: (context, index) => AquaNavBarItem(
                              onTap: () => AquaTooltip.show(
                                context,
                                message: '${items2[index].label} tapped',
                              ),
                              icon: items2[index].icon,
                              label: items2[index].label,
                              colors: theme.colors,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AquaNavBar(
                            colors: theme.colors,
                            itemCount: items3.length,
                            itemBuilder: (context, index) => AquaNavBarItem(
                              onTap: () => AquaTooltip.show(
                                context,
                                message: '${items3[index].label} tapped',
                              ),
                              icon: items3[index].icon,
                              label: items3[index].label,
                              colors: theme.colors,
                            ),
                          ),
                          const SizedBox(height: 16),
                          AquaNavBar(
                            colors: theme.colors,
                            itemCount: items4.length,
                            itemBuilder: (context, index) => AquaNavBarItem(
                              onTap: () => AquaTooltip.show(
                                context,
                                message: '${items4[index].label} tapped',
                              ),
                              icon: items4[index].icon,
                              label: items4[index].label,
                              colors: theme.colors,
                            ),
                          ),
                          Builder(
                            builder: (context) => AquaButton.tertiary(
                              text: 'Close',
                              onPressed: Navigator.of(context).pop,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 375),
                      child: Stack(
                        children: [
                          Column(
                            children: [
                              for (var i = 0; i < 10; i++) ...{
                                const AquaText.body1SemiBold(text: _lorem),
                                const SizedBox(height: 10),
                              },
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                alignment: Alignment.centerRight,
                                margin: const EdgeInsets.all(16),
                                child: AquaFloatingActionButton(
                                  icon: AquaIcon.swap,
                                  onTap: () => AquaTooltip.show(
                                    context,
                                    message: 'FAB tapped',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              AquaNavBar(
                                colors: theme.colors,
                                itemCount: items1.length,
                                itemBuilder: (context, index) => AquaNavBarItem(
                                  onTap: () {
                                    if (selectedBottomNavIndex.value != index) {
                                      selectedBottomNavIndex.value = index;
                                      AquaTooltip.show(
                                        context,
                                        message:
                                            '${items1[index].label} selected',
                                      );
                                    }
                                  },
                                  isSelected:
                                      selectedBottomNavIndex.value == index,
                                  icon: items1[index].icon,
                                  label: items1[index].label,
                                  colors: theme.colors,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AquaNavBar(
                                colors: theme.colors,
                                itemCount: items2.length,
                                itemBuilder: (context, index) => AquaNavBarItem(
                                  onTap: () => AquaTooltip.show(
                                    context,
                                    message: '${items2[index].label} tapped',
                                  ),
                                  icon: items2[index].icon,
                                  label: items2[index].label,
                                  colors: theme.colors,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AquaNavBar(
                                colors: theme.colors,
                                itemCount: items3.length,
                                itemBuilder: (context, index) => AquaNavBarItem(
                                  onTap: () => AquaTooltip.show(
                                    context,
                                    message: '${items3[index].label} tapped',
                                  ),
                                  icon: items3[index].icon,
                                  label: items3[index].label,
                                  colors: theme.colors,
                                ),
                              ),
                              const SizedBox(height: 16),
                              AquaNavBar(
                                colors: theme.colors,
                                itemCount: items4.length,
                                itemBuilder: (context, index) => AquaNavBarItem(
                                  onTap: () => AquaTooltip.show(
                                    context,
                                    message: '${items4[index].label} tapped',
                                  ),
                                  icon: items4[index].icon,
                                  label: items4[index].label,
                                  colors: theme.colors,
                                ),
                              ),
                              Builder(
                                builder: (context) => AquaButton.tertiary(
                                  text: 'Close',
                                  onPressed: Navigator.of(context).pop,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
