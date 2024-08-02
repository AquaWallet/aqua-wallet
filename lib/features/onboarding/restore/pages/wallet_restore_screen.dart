import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WalletRestoreScreen extends HookConsumerWidget {
  static const routeName = '/walletRestorePrompt';

  const WalletRestoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      Future.microtask(() {
        ref.read(systemOverlayColorProvider(context)).forceLight();
      });
      return null;
    }, []);

    return PopScope(
      canPop: true,
      onPopInvoked: (_) async {
        ref.read(systemOverlayColorProvider(context)).aqua();
      },
      child: Scaffold(
        appBar: AquaAppBar(
          showBackButton: false,
          showActionButton: true,
          iconBackgroundColor: Theme.of(context).colorScheme.background,
          iconForegroundColor: Theme.of(context).colorScheme.onBackground,
          actionButtonAsset: Svgs.close,
          actionButtonIconSize: 13.r,
          onActionButtonPressed: () {
            ref.read(systemOverlayColorProvider(context)).aqua();
            Navigator.of(context).pop();
          },
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.h),
                SvgPicture.asset(
                  Svgs.recoveryPhrase,
                  width: 73.w,
                  height: 61.h,
                ),
                SizedBox(height: 43.h),
                Text(
                  context.loc.restorePromptTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                SizedBox(height: 20.h),
                Text(
                  context.loc.restorePromptSubtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 16.sp,
                      ),
                ),
                const Spacer(),
                AquaElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamed(WalletRestoreInputScreen.routeName),
                  child: Text(context.loc.restorePromptButton),
                ),
                SizedBox(height: 66.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
