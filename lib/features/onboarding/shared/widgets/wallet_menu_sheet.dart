import 'package:aqua/common/common.dart';
import 'package:aqua/data/provider/register_wallet/register_wallet_provider.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletMenuSheet extends HookConsumerWidget {
  const WalletMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.read(lightThemeProvider(context)).colorScheme;
    final tosAccepted = useState(false);

    final buttonStyle = useMemoized(() {
      return ElevatedButton.styleFrom(
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(9.r),
        ),
        textStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.w700,
          fontFamily: UiFontFamily.dMSans,
        ),
      );
    });

    final showUnacceptedConditionError = useCallback(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          key: const Key('welcome-unaccepted-condition'),
          content: Text(
            !tosAccepted.value
                ? context.loc.welcomeScreenUnacceptedToSError
                : context.loc.welcomeScreenUnacceptedDisclaimerError,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onError,
                ),
          ),
          backgroundColor: colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
    }, [tosAccepted.value]);

    final changeStatusBarColor = useCallback(() {
      return Future.microtask(
        () => ref.read(systemOverlayColorProvider(context)).forceLight(),
      );
    }, []);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //ANCHOR - Create Button
            AquaElevatedButton(
              key: const Key('welcome-create-btn'),
              style: buttonStyle,
              onPressed: () {
                if (!tosAccepted.value) {
                  showUnacceptedConditionError();
                } else {
                  changeStatusBarColor();
                  ref.read(registerWalletProvider).register();
                }
              },
              child: Text(context.loc.createWallet),
            ),
            SizedBox(height: 20.h),
            //ANCHOR - Restore Button
            AquaElevatedButton(
              key: const Key('welcome-restore-btn'),
              style: buttonStyle,
              onPressed: () {
                if (!tosAccepted.value) {
                  showUnacceptedConditionError();
                } else {
                  changeStatusBarColor();

                  Navigator.of(context)
                    ..popUntil((r) => r.isFirst)
                    ..pushNamed(WalletRestoreScreen.routeName);
                }
              },
              child: Text(context.loc.restoreWallet),
            ),
            SizedBox(height: 23.h),
            WelcomeToSCheckbox(onTosAccepted: tosAccepted),
            SizedBox(height: 9.h),
          ],
        ),
      ),
    );
  }
}
