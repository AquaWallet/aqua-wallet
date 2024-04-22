import 'dart:io';

import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/backup/backup.dart';
import 'package:aqua/features/recovery/recovery.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/services.dart';

class WalletRecoveryPhraseScreen extends StatefulHookConsumerWidget {
  static const routeName = '/walletRecoveryPhraseScreen';

  const WalletRecoveryPhraseScreen({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _State();
}

class _State extends ConsumerState<WalletRecoveryPhraseScreen> {
  static const platform = MethodChannel('com.example.aqua/utils');

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      platform.invokeMethod<bool>('addWindowSecureFlags');
    } else if (Platform.isIOS) {
      platform.invokeMethod<bool>('addScreenshotNotificationObserver');
      platform.setMethodCallHandler((call) async {
        Future.microtask(() => showModalBottomSheet(
              context: context,
              isDismissible: false,
              isScrollControlled: false,
              backgroundColor: Theme.of(context).colorScheme.background,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30.r),
                  topRight: Radius.circular(30.r),
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
    final arguments = ModalRoute.of(context)!.settings.arguments
        as RecoveryPhraseScreenArguments?;

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: true,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.r,
        onActionButtonPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 28.w),
          child: Column(
            children: [
              SizedBox(height: 16.h),
              const RecoveryPhraseWidget(),
              const Spacer(),
              if (arguments?.isOnboarding ?? true) ...[
                AquaElevatedButton(
                  child: Text(
                    context.loc.backupRecoveryPhraseButton,
                  ),
                  onPressed: () => Navigator.of(context)
                      .pushReplacementNamed(WalletBackupConfirmation.routeName),
                ),
                SizedBox(height: 66.h),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
