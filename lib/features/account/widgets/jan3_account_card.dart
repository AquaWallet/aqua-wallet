import 'package:aqua/config/constants/urls.dart';
import 'package:aqua/features/account/models/auth_state.dart';
import 'package:aqua/features/account/pages/jan3_login_screen.dart';
import 'package:aqua/features/account/providers/providers.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ui_components/ui_components.dart';

class Jan3AccountCard extends HookConsumerWidget {
  final bool isExpanded;
  final VoidCallback? onClose;

  const Jan3AccountCard({
    super.key,
    this.isExpanded = true,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountState = ref.watch(currentWalletAuthProvider);
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final isLoggedIn = accountState.isAuthenticated;

    final shareInvite = useCallback(() {
      final message = context.loc.jan3InviteMessage(aquaDownloadUrl);
      Share.share(message, sharePositionOrigin: context.sharePositionOrigin);
    }, [context]);

    // Card content widget
    final cardContent = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Jan3 Logo
              darkMode
                  ? UiAssets.svgs.dark.jan3MiniLogo.svg(
                      width: 40,
                      height: 40,
                    )
                  : UiAssets.svgs.light.jan3MiniLogo.svg(
                      width: 40,
                      height: 40,
                    ),
              const SizedBox(width: 24),
              // Account Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AquaText.body1SemiBold(
                      text: context.loc.jan3AccountTitle,
                    ),
                    AquaText.body2Medium(
                      text: accountState.mapOrNull(
                            authenticated: (state) => state.profile.email,
                          ) ??
                          context.loc.unlockMoreFeatures,
                      color: context.aquaColors.textSecondary,
                    ),
                  ],
                ),
              ),
              // Close button
              isLoggedIn
                  ? const SizedBox.shrink()
                  : AquaIcon.close(
                      size: 18,
                      color: context.aquaColors.textTertiary,
                      onTap: onClose,
                    ),
            ],
          ),
        ),
        AquaDivider(
          colors: context.aquaColors,
        ),
        // Action Buttons
        Row(
          children: [
            Flexible(
              fit: FlexFit.tight,
              child: InkWell(
                borderRadius: isLoggedIn
                    ? const BorderRadius.only(bottomLeft: Radius.circular(8))
                    : const BorderRadius.vertical(bottom: Radius.circular(8)),
                onTap: () {
                  if (isLoggedIn) {
                    shareInvite();
                  } else {
                    context.push(Jan3LoginScreen.routeName);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Center(
                    child: AquaText.body2SemiBold(
                      text: isLoggedIn
                          ? context.loc.jan3InviteFriends
                          : context.loc.loginScreenTitle,
                    ),
                  ),
                ),
              ),
            ),
            if (isLoggedIn) ...[
              SizedBox(
                height: 48,
                width: 1,
                child: ColoredBox(
                  color: context.aquaColors.surfaceBackground,
                ),
              ),
              Flexible(
                fit: FlexFit.tight,
                child: InkWell(
                  borderRadius:
                      const BorderRadius.only(bottomRight: Radius.circular(8)),
                  onTap: () {
                    ref.read(currentWalletAuthProvider.notifier).signOut();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    child: Center(
                      child: AquaText.body2SemiBold(
                        text: context.loc.jan3LogOut,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isExpanded ? 121 : 0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
      ),
      child: AquaCard(
        borderRadius: BorderRadius.circular(8),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: isExpanded ? 1.0 : 0.0,
          child: isExpanded
              ? cardContent
              : const SizedBox.shrink(), // Don't render content when collapsed
        ),
      ),
    );
  }
}
