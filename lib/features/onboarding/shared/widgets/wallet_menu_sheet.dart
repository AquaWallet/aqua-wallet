import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/register_wallet/register_wallet_provider.dart';
import 'package:aqua/data/provider/theme_provider.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletMenuSheet extends HookConsumerWidget {
  const WalletMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = ref.read(lightThemeProvider(context)).colorScheme;
    final tosAccepted = useState(false);

    final showUnacceptedConditionError = useCallback(() {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 56.h),
          //ANCHOR - Wallet Icon
          SvgPicture.asset(
            Svgs.welcomeWallet,
            width: 60.r,
            height: 60.r,
          ),
          SizedBox(height: 16.h),
          //ANCHOR - Title
          Text(
            context.loc.welcomeScreenTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.sp,
                  color: colorScheme.onBackground,
                ),
          ),
          SizedBox(height: 16.h),
          //ANCHOR - Description
          Text(
            context.loc.welcomeScreenDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  color: colorScheme.onBackground,
                ),
          ),
          SizedBox(height: 36.h),
          //ANCHOR - Create Button
          WalletButton(
            onPressed: () {
              if (!tosAccepted.value) {
                showUnacceptedConditionError();
              } else {
                changeStatusBarColor();
                ref.read(registerWalletProvider).register();
              }
            },
            iconSvg: Svgs.createWallet,
            iconSize: 48.w,
            paddingStart: 3.w,
            paddingIcon: 14.w,
            title: context.loc.welcomeScreenCreateButtonTitle,
            description: context.loc.welcomeScreenCreateButtonDescription,
          ),
          SizedBox(height: 8.h),
          //ANCHOR - Restore Button
          WalletButton(
            onPressed: () {
              if (!tosAccepted.value) {
                showUnacceptedConditionError();
              } else {
                changeStatusBarColor();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  WalletRestoreScreen.routeName,
                  (route) => route is! RawDialogRoute,
                );
              }
            },
            iconSvg: Svgs.restoreWallet,
            iconSize: 38.w,
            paddingStart: 8.w,
            paddingIcon: 17.w,
            title: context.loc.welcomeScreenRestoreButtonTitle,
            description: context.loc.welcomeScreenRestoreButtonDescription,
          ),
          SizedBox(height: 16.h),
          WelcomeToSCheckbox(onTosAccepted: tosAccepted),
          SizedBox(height: 58.h),
        ],
      ),
    );
  }
}
