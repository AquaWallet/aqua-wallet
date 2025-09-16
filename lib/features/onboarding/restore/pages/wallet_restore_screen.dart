import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/onboarding/onboarding.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
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
          iconBackgroundColor: Theme.of(context).colors.background,
          iconForegroundColor: Theme.of(context).colors.onBackground,
          actionButtonAsset: Svgs.close,
          actionButtonIconSize: 13.0,
          onActionButtonPressed: () {
            ref.read(systemOverlayColorProvider(context)).aqua();
            context.pop();
          },
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4.0),
                SvgPicture.asset(
                  Svgs.recoveryPhrase,
                  width: 73.0,
                  height: 61.0,
                ),
                const SizedBox(height: 43.0),
                Text(
                  context.loc.restorePromptTitle,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20.0),
                Text(
                  context.loc.restorePromptSubtitle,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 16.0,
                      ),
                ),
                const Spacer(),
                AquaElevatedButton(
                  onPressed: () =>
                      context.push(WalletRestoreInputScreen.routeName),
                  child: Text(context.loc.restorePromptButton),
                ),
                const SizedBox(height: 66.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
