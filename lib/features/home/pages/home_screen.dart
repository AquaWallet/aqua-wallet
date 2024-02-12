import 'package:aqua/common/widgets/custom_bottom_navigation_bar.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/home/providers/home_provider.dart';
import 'package:aqua/features/marketplace/marketplace.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/wallet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:aqua/config/constants/urls.dart' as urls;

class HomeScreen extends StatefulHookConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  static const routeName = '/home';

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => State();
}

class State extends ConsumerState<HomeScreen> {
  WebViewController? _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (int progress) {},
        onPageStarted: (String url) {},
        onPageFinished: (String url) {},
        onWebResourceError: (WebResourceError error) {},
      ))
      // we are doing this so we load the boltz js code and perform any
      // pending claims. native integration coming soon
      // also setting the referral code to 'AQUA'
      ..loadRequest(Uri.parse("${urls.boltzWebAppUrl}refund/?ref=AQUA"));
  }

  @override
  Widget build(BuildContext context) {
    final visible = ref.watch(homeContentVisibilityProvider);
    final selectedTab = ref.watch(homeSelectedBottomTabProvider);
    final hasTransacted = ref.watch(hasTransactedProvider).asData?.value;

    ref.watch(availableAssetsProvider);

    useEffect(() {
      Future.microtask(() {
        final showBackupFlow = ref
            .read(backupReminderProvider.select((p) => p.shouldShowBackupFlow));
        if (hasTransacted == true && showBackupFlow) {
          Navigator.of(context).pushNamed(WalletBackupScreen.routeName);
        }
      });
      return null;
    }, [hasTransacted]);

    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).themeBased();
      });
      return null;
    }, []);

    return Visibility(
      visible: visible,
      child: WillPopScope(
        onWillPop: () async {
          if (selectedTab != WalletTabs.wallet) {
            ref.read(homeProvider).selectTab(0);
            return false;
          } else {
            return true;
          }
        },
        child: AnnotatedRegion(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
          ),
          child: Scaffold(
            body: Stack(
              children: [
                switch (selectedTab) {
                  WalletTabs.wallet => const WalletTab(),
                  WalletTabs.marketplace => const MarketplaceTab(),
                  WalletTabs.settings => const SettingsTab(),
                },
                if (_controller != null) ...[
                  SizedBox(
                    height: 0.h,
                    child: WebViewWidget(controller: _controller!),
                  )
                ]
              ],
            ),
            bottomNavigationBar: CustomBottomNavigationBar(
              currentIndex: selectedTab.index,
              onTap: (index) => ref.read(homeProvider).selectTab(index),
            ),
          ),
        ),
      ),
    );
  }
}
