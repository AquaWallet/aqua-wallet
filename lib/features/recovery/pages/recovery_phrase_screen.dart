import 'dart:io';

import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/backup/backup.dart';
import 'package:coin_cz/features/recovery/recovery.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/services.dart';

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.0,
        onActionButtonPressed: () => context.pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12.0),
                  Text(
                    context.loc.backupRecoveryPhraseTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          letterSpacing: 1,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 18.0),
                  Text(
                    context.loc.backupRecoveryPhraseSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          letterSpacing: .15,
                          height: 1.2,
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 36.0),
                    child: WalletBackupMnemonicWords(),
                  ),
                ],
              ),
              const Spacer(),
              if (arguments.isOnboarding) ...[
                AquaElevatedButton(
                  child: Text(
                    context.loc.continueLabel,
                  ),
                  onPressed: () => context
                      .pushReplacement(WalletBackupConfirmation.routeName),
                ),
                const SizedBox(height: 66.0),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
