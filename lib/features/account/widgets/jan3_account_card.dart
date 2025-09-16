import 'package:coin_cz/config/constants/urls.dart';
import 'package:coin_cz/features/account/models/auth_state.dart';
import 'package:coin_cz/features/account/pages/jan3_login_screen.dart';
import 'package:coin_cz/features/account/providers/providers.dart';
import 'package:coin_cz/features/settings/shared/providers/prefs_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';

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
    final accountState = ref.watch(jan3AuthProvider).valueOrNull;
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
    final isLoggedIn = accountState?.isAuthenticated ?? false;

    final shareInvite = useCallback(() {
      final message = context.loc.jan3InviteMessage(aquaDownloadUrl);
      Share.share(message);
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
                    Text(
                      context.loc.jan3AccountTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                        accountState?.mapOrNull(
                              authenticated: (state) => state.profile.email,
                            ) ??
                            context.loc.jan3UnlockFeatures,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            )),
                  ],
                ),
              ),
              // Close button
              IconButton(
                icon: UiAssets.cross.svg(
                  width: 10,
                  height: 10,
                ),
                onPressed: onClose,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        Divider(
          color: context.colors.divider,
          thickness: 1,
          height: 1,
        ),
        // Action Buttons
        IntrinsicHeight(
            child: Row(
          children: [
            // First Button (Invite Friends or Log In)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (isLoggedIn) {
                    shareInvite();
                  } else {
                    context.push(Jan3LoginScreen.routeName);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      isLoggedIn
                          ? context.loc.jan3InviteFriends
                          : context.loc.jan3Login,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            // Vertical Divider
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: context.colors.divider,
            ),
            // Second Button (Log Out or Create Account)
            Expanded(
              child: InkWell(
                onTap: () {
                  if (isLoggedIn) {
                    ref.read(jan3AuthProvider.notifier).signOut();
                  } else {
                    context.push(Jan3LoginScreen.routeName);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Center(
                    child: Text(
                      isLoggedIn ? context.loc.jan3LogOut : context.loc.signUp,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        )),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: isExpanded ? 134 : 0,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
