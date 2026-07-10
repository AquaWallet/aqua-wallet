import 'package:aqua/config/config.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/lightning_address/lightning_address.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

final _logger = CustomLogger(FeatureFlag.lightningAddress);

int _lnAddressEditPageIndex(LnAddressEditStep? step) => switch (step) {
      null || LnAddressEditStep.pay => 0,
      LnAddressEditStep.confirm => 1,
    };

class LnAddressEditArguments {
  const LnAddressEditArguments({required this.username});

  final String username;
}

class LnAddressEditScreen extends HookConsumerWidget {
  const LnAddressEditScreen({
    super.key,
    required this.arguments,
  });

  final LnAddressEditArguments arguments;

  static const routeName = '/lnAddressEditScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStep = ref.watch(lnAddressEditStepProvider);
    ref.watch(lnAddressEditInputProvider).valueOrNull;
    final walletId = ref.watch(currentWalletIdSyncProvider);

    ref.listen(lnAddressUpdatePaymentProvider, (prev, next) {
      if (prev?.isLoading == true && next.hasValue) {
        ref.invalidate(jan3AuthProvider(walletId));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            AquaModalSheet.show(
              context,
              icon: AquaIcon.checkCircle(color: Colors.white),
              iconVariant: AquaRingedIconVariant.info,
              title: context.loc.lnAddressEditPaymentApproved,
              message: context.loc.lnAddressEditPaymentApprovedMessage,
              primaryButtonText: context.loc.ok,
              onPrimaryButtonTap: () {
                context.pop();
                context.popUntilPath(AccountSettingsScreen.routeName);
              },
              onDismiss: () =>
                  context.popUntilPath(AccountSettingsScreen.routeName),
              colors: context.aquaColors,
              copiedToClipboardText: context.loc.copiedToClipboard,
            );
          }
        });
      }
      if (next.hasError) {
        final error = next.error!;
        final stackTrace = next.stackTrace;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _logger.error(
            '[LnAddressEdit] Payment update failed',
            error,
            stackTrace,
          );
          if (context.mounted) {
            AquaModalSheet.show(
              context,
              icon: AquaIcon.warning(color: Colors.white),
              iconVariant: AquaRingedIconVariant.warning,
              title: context.loc.lnAddressChangeFailed,
              message: context.loc.lnAddressChangeFailedMessage,
              primaryButtonText: context.loc.ok,
              onPrimaryButtonTap: () {
                context.pop();
                context.popUntilPath(AccountSettingsScreen.routeName);
              },
              onDismiss: () =>
                  context.popUntilPath(AccountSettingsScreen.routeName),
              secondaryButtonText: context.loc.commonContactSupport,
              onSecondaryButtonTap: () {
                context.pop();
                context.replace(HelpSupportScreen.routeName);
              },
              colors: context.aquaColors,
              copiedToClipboardText: context.loc.copiedToClipboard,
            );
          }
        });
      }
    });

    ref.listen(lnAddressPaymentRequestProvider, (prev, next) {
      if (next.hasError && prev?.hasError != true) {
        final error = next.error!;
        final stackTrace = next.stackTrace;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _logger.error(
            '[LnAddressEdit] Payment request failed',
            error,
            stackTrace,
          );
          if (context.mounted) {
            AquaModalSheet.show(
              context,
              icon: AquaIcon.warning(color: Colors.white),
              iconVariant: AquaRingedIconVariant.warning,
              title: context.loc.lnAddressEditPaymentRequestFailed,
              message: context.loc.lnAddressEditPaymentRequestFailedMessage,
              primaryButtonText: context.loc.ok,
              onPrimaryButtonTap: () {
                context.pop();
                ref.invalidate(lnAddressPaymentRequestProvider);
                context.pop();
              },
              onDismiss: () {
                ref.invalidate(lnAddressPaymentRequestProvider);
                context.pop();
              },
              secondaryButtonText: context.loc.commonContactSupport,
              onSecondaryButtonTap: () {
                context.pop();
                ref.invalidate(lnAddressPaymentRequestProvider);
                context.replace(HelpSupportScreen.routeName);
              },
              colors: context.aquaColors,
              copiedToClipboardText: context.loc.copiedToClipboard,
            );
          }
        });
      }
    });

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(lnAddressEditInputProvider.notifier)
            .prefillUsername(arguments.username);
        if (currentStep == null) {
          ref
              .read(lnAddressEditStepProvider.notifier)
              .setStep(LnAddressEditStep.pay);
        }
      });
      return null;
    }, const []);

    final onBackPressed = useCallback(() {
      final previousStep =
          ref.read(lnAddressEditStepProvider.notifier).goBack();
      if (previousStep == null) {
        context.pop();
      }
    }, []);

    final title = switch (currentStep) {
      LnAddressEditStep.confirm => context.loc.lnAddressEditConfirmPurchase,
      _ => context.loc.lnAddressEditPayWith,
    };

    final pageController = usePageController(
      initialPage: _lnAddressEditPageIndex(currentStep),
      keepPage: true,
    );

    ref.listen(lnAddressEditStepProvider, (previous, next) {
      FocusScope.of(context).unfocus();
      final targetIndex = _lnAddressEditPageIndex(next);
      final currentIndex = pageController.page?.round() ?? 0;
      final distance = (targetIndex - currentIndex).abs();
      final duration = distance > 1
          ? const Duration(milliseconds: 100)
          : const Duration(milliseconds: 200);
      pageController.animateToPage(
        targetIndex,
        duration: duration,
        curve: Curves.easeInOut,
      );
    });

    return PopScope(
      canPop: currentStep == LnAddressEditStep.pay,
      onPopInvoked: (didPop) {
        if (!didPop) {
          onBackPressed();
        }
      },
      child: DesignRevampScaffold(
        appBar: AquaTopAppBar(
          showBackButton: true,
          title: title,
          colors: context.aquaColors,
          onBackPressed: onBackPressed,
        ),
        body: SafeArea(
          child: PageView(
            physics: const NeverScrollableScrollPhysics(),
            controller: pageController,
            children: const [
              LnAddressPayWithPage(),
              LnAddressConfirmPurchasePage(),
            ],
          ),
        ),
      ),
    );
  }
}
