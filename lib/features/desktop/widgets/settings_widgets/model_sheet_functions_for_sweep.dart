import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/layout/default_desktop_layout.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:ui_components/ui_components.dart';

class ModelSheetFunctionsForSweep {
  static void showModelSheet({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required isSuccess,
  }) {
    if (isSuccess) {
      AquaModalSheet.show(
        desktopGlobalKey.currentState!.context,
        title: 'Sweep Complete',
        message: 'Your sweep was successful!',
        primaryButtonText: loc.debitCardWaitlistButton,
        onPrimaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        secondaryButtonText: loc.commonSwapViewReceipt,
        onSecondaryButtonTap: () {
          final mainContext = desktopGlobalKey.currentState!.context;
          mainContext.pop();
          BitcoinShowRecipientSideSheet.show(
            context: mainContext,
            aquaColors: aquaColors,
            loc: loc,
          );
        },
        icon: AquaIcon.pending(
          color: aquaColors.textTertiary,
        ),
        iconVariant: AquaRingedIconVariant.info,
        colors: aquaColors,
        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard,
      );
    } else {
      AquaModalSheet.show(
        desktopGlobalKey.currentState!.context,
        title: 'Sweep Failed',
        message: 'Something went wrong.',
        primaryButtonText: loc.tryAgain,
        onPrimaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        secondaryButtonText: loc.commonContactSupport,

        ///TODO: Implement contact support action
        onSecondaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        icon: AquaIcon.warning(
          color: Colors.white,
        ),
        iconVariant: AquaRingedIconVariant.warning,
        copyableContentTitle: loc.details,
        copyableContentMessage:
            '400: RequestOptions.validateStatus was configured to throw for this status code.',
        colors: aquaColors,
        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard,
      );
    }
  }
}

class ModelSheetFunctionsForDolphinTopUp {
  static void showModelSheet({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required isSuccess,
  }) {
    if (isSuccess) {
      AquaModalSheet.show(
        desktopGlobalKey.currentState!.context,
        title: 'Top-up in Progress',
        message:
            'Your top up is in progress. It will be available on your card soon.',
        primaryButtonText: 'Got it!',
        onPrimaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        secondaryButtonText: 'View Reiceipt',
        onSecondaryButtonTap: () {
          final mainContext = desktopGlobalKey.currentState!.context;
          mainContext.pop();
        },
        icon: AquaIcon.checkCircle(
          color: Colors.white,
        ),
        iconVariant: AquaRingedIconVariant.info,
        colors: aquaColors,
        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard,
      );
    } else {
      AquaModalSheet.show(
        desktopGlobalKey.currentState!.context,
        title: 'Top-up Failed',
        message: 'Something went wrong.',
        primaryButtonText: loc.tryAgain,
        onPrimaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        secondaryButtonText: loc.commonContactSupport,

        ///TODO: Implement contact support action
        onSecondaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        icon: AquaIcon.warning(
          color: Colors.white,
        ),
        iconVariant: AquaRingedIconVariant.warning,
        copyableContentTitle: loc.details,
        copyableContentMessage:
            '400: RequestOptions.validateStatus was configured to throw for this status code.',
        colors: aquaColors,
        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard,
      );
    }
  }
}

class ModelSheetFunctionsForSwap {
  /// Shows a Peg-in Transaction info modal
  static void showPegInInfo({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    AquaModalSheet.show(
      context,
      title: 'Peg-in Transaction',
      message: loc.swapPanelPegInInfo,
      primaryButtonText: 'Got it!',
      onPrimaryButtonTap: () => Navigator.pop(context),
      icon: AquaIcon.pegIn(
        color: aquaColors.textTertiary,
      ),
      iconVariant: AquaRingedIconVariant.normal,
      colors: aquaColors,
      bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
      copiedToClipboardText: loc.copiedToClipboard,
    );
  }

  /// Shows a Peg-out Transaction info modal
  static void showPegOutInfo({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    AquaModalSheet.show(
      context,
      title: 'Peg-out Transaction',
      message: loc.swapPanelPegOutInfo,
      primaryButtonText: 'Got it!',
      onPrimaryButtonTap: () => Navigator.pop(context),
      icon: AquaIcon.infoCircle(
        color: aquaColors.textTertiary,
      ),
      iconVariant: AquaRingedIconVariant.normal,
      colors: aquaColors,
      bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
      copiedToClipboardText: loc.copiedToClipboard,
    );
  }

  /// Shows a Swap Failed error modal
  static void showSwapFailed({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    String? errorDetails,
    VoidCallback? onRetry,
    VoidCallback? onContactSupport,
  }) {
    AquaModalSheet.show(
      context,
      title: loc.swapFailed,
      message: loc.commonSomethingWentWrong,
      primaryButtonText: loc.tryAgain,
      onPrimaryButtonTap: onRetry ?? () => Navigator.pop(context),
      secondaryButtonText: loc.commonContactSupport,
      onSecondaryButtonTap: onContactSupport ??
          () {
            // TODO: Implement contact support action
            Navigator.pop(context);
          },
      icon: AquaIcon.warning(
        color: Colors.white,
      ),
      iconVariant: AquaRingedIconVariant.warning,
      copyableContentTitle: loc.details,
      copyableContentMessage: errorDetails ??
          '400: RequestOptions.validateStatus was configured to throw for this status code.',
      colors: aquaColors,
      bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
      copiedToClipboardText: loc.copiedToClipboard,
    );
  }

  /// Shows a Swap Complete success modal
  static void showSwapComplete({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    VoidCallback? onViewReceipt,
  }) {
    AquaModalSheet.show(context,
        title: loc.commonSwapComplete,
        message: loc.commonYourSwapWasSuccessful,
        primaryButtonText: loc.commonGotIt,
        onPrimaryButtonTap: () => Navigator.pop(context),
        secondaryButtonText: loc.commonSwapViewReceipt,
        onSecondaryButtonTap: onViewReceipt ??
            () {
              // TODO: Implement view receipt action
              Navigator.pop(context);
            },
        icon: AquaIcon.checkCircle(
          color: Colors.white,
        ),
        iconVariant: AquaRingedIconVariant.info,
        colors: aquaColors,
        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard);
  }

  /// Shows a Swap Initiated modal
  static void showSwapInitiated({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    VoidCallback? onViewReceipt,
  }) {
    AquaModalSheet.show(
      context,
      title: loc.commonSwapInitiated,
      message: loc.swapInitiatedMessage,
      primaryButtonText: loc.commonGotIt,
      onPrimaryButtonTap: () => Navigator.pop(context),
      secondaryButtonText: loc.commonSwapViewReceipt,
      onSecondaryButtonTap: onViewReceipt ??
          () {
            // TODO: Implement view receipt action
            Navigator.pop(context);
          },
      icon: AquaIcon.pending(
        color: aquaColors.textTertiary,
      ),
      colors: aquaColors,
      bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
      copiedToClipboardText: loc.copiedToClipboard,
    );
  }

  /// Convenience method that handles different swap states
  static void showSwapModal({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required SwapModalType type,
    String? errorDetails,
    VoidCallback? onRetry,
    VoidCallback? onContactSupport,
    VoidCallback? onViewReceipt,
  }) {
    switch (type) {
      case SwapModalType.pegIn:
        showPegInInfo(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
        break;
      case SwapModalType.pegOut:
        showPegOutInfo(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
        );
        break;
      case SwapModalType.failed:
        showSwapFailed(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          errorDetails: errorDetails,
          onRetry: onRetry,
          onContactSupport: onContactSupport,
        );
        break;
      case SwapModalType.complete:
        showSwapComplete(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          onViewReceipt: onViewReceipt,
        );
        break;
      case SwapModalType.initiated:
        showSwapInitiated(
          context: context,
          aquaColors: aquaColors,
          loc: loc,
          onViewReceipt: onViewReceipt,
        );
        break;
    }
  }
}

/// Enum to define different swap modal types
enum SwapModalType {
  pegIn,
  pegOut,
  failed,
  complete,
  initiated,
}

class ModelSheetFunctionsForSend {
  static void showModelSheet({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
    required isSuccess,
  }) {
    if (isSuccess) {
      AquaModalSheet.show(
        desktopGlobalKey.currentState!.context,
        title: 'Send Complete',
        message: 'Your send was successful!',
        primaryButtonText: loc.commonGotIt,
        onPrimaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        secondaryButtonText: loc.commonSwapViewReceipt,
        onSecondaryButtonTap: () {
          final mainContext = desktopGlobalKey.currentState!.context;
          mainContext.pop();
        },
        icon: AquaIcon.checkCircle(
          color: Colors.white,
        ),
        iconVariant: AquaRingedIconVariant.info,
        colors: aquaColors,
        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard,
      );
    } else {
      AquaModalSheet.show(
        colors: aquaColors,
        desktopGlobalKey.currentState!.context,
        title: loc.commonSendFailed,
        message: loc.commonSomethingWentWrong,
        primaryButtonText: loc.tryAgain,
        onPrimaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        secondaryButtonText: loc.commonContactSupport,

        ///TODO: Implement contact support action
        onSecondaryButtonTap: desktopGlobalKey.currentState!.context.pop,
        icon: AquaIcon.warning(
          color: Colors.white,
        ),
        iconVariant: AquaRingedIconVariant.warning,
        copyableContentTitle: loc.details,
        copyableContentMessage:
            '400: RequestOptions.validateStatus was configured to throw for this status code.',

        bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
        copiedToClipboardText: loc.copiedToClipboard,
      );
    }
  }
}
