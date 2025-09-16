import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/recovery/recovery.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletBackupConfirmationFailure extends HookConsumerWidget {
  static const routeName = '/walletBackupConfirmationFailure';

  const WalletBackupConfirmationFailure({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onRetry = useCallback(
      () => context.pushReplacement(WalletRecoveryPhraseScreen.routeName),
      [],
    );

    return Scaffold(
      appBar: AquaAppBar(
        showActionButton: false,
        iconBackgroundColor: Theme.of(context).colors.background,
        iconForegroundColor: Theme.of(context).colors.onBackground,
        onBackPressed: onRetry,
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 60.0),
              const Spacer(),
              //ANCHOR - Icon
              SvgPicture.asset(
                Svgs.failure,
                width: 60.0,
                height: 60.0,
              ),
              const SizedBox(height: 20.0),
              //ANCHOR - Title
              Text(
                context.loc.somethingWentWrong,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 20.0,
                    ),
              ),
              const SizedBox(height: 8.0),
              //ANCHOR - Description
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  context.loc.backupFailureDescription,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colors.onBackground,
                      ),
                ),
              ),
              const Spacer(),
              //ANCHOR - Quit button
              AquaElevatedButton(
                child: Text(
                  context.loc.backupFailureQuitButton,
                ),
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 27.0),
              //ANCHOR - Retry button
              AquaElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  context.loc.retry,
                ),
              ),
              const SizedBox(height: 64.0),
            ],
          ),
        ),
      ),
    );
  }
}
