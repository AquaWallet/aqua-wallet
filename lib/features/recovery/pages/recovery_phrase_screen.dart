import 'dart:io';

import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class WalletRecoveryPhraseScreen extends StatefulHookConsumerWidget {
  static const routeName = '/walletRecoveryPhraseScreen';

  const WalletRecoveryPhraseScreen({super.key, required this.arguments});
  final RecoveryPhraseScreenArguments arguments;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _State();
}

class _State extends ConsumerState<WalletRecoveryPhraseScreen> {
  static const platform = MethodChannel('com.example.aqua/utils');

  late RecoveryPhraseScreenArguments arguments;

  @override
  void initState() {
    super.initState();
    arguments = widget.arguments;

    if (Platform.isAndroid) {
      platform.invokeMethod<bool>('addWindowSecureFlags');
    } else if (Platform.isIOS) {
      platform.invokeMethod<bool>('addScreenshotNotificationObserver');
      platform.setMethodCallHandler((call) async {
        Future.microtask(() => showModalBottomSheet(
              context: context,
              isDismissible: false,
              isScrollControlled: false,
              backgroundColor: Theme.of(context).colors.background,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.0),
                  topRight: Radius.circular(30.0),
                ),
              ),
              builder: (_) => const ScreenshotWarningSheet(),
            ));
      });
    }
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      platform.invokeMethod<bool>('clearWindowSecureFlags');
    } else if (Platform.isIOS) {
      platform.invokeMethod<bool>('removeScreenshotNotificationObserver');
    }

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final isHidden = useState(false);
    return Scaffold(
      appBar: AquaTopAppBar(
        colors: context.aquaColors,
        title: context.loc.seedPhraseTitle,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WalletBackupMnemonicWords(
                isHidden: isHidden.value,
                walletId: arguments.walletId,
              ),
              Column(
                children: [
                  if (!arguments.isOnboarding) ...[
                    AquaButton.secondary(
                      text: context.loc.hideSeedPhrase,
                      onPressed: () => isHidden.value = !isHidden.value,
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (arguments.isOnboarding) ...[
                    AquaButton.primary(
                      text: context.loc.continueLabel,
                      onPressed: () => context
                          .pushReplacement(WalletBackupConfirmation.routeName),
                    ),
                  ]
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
