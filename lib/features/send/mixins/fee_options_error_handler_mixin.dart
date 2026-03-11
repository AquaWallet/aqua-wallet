import 'package:aqua/common/common.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

mixin FeeOptionsErrorHandlerMixin {
  /// Sets up error handling for fee options provider
  void setupFeeOptionsErrorHandler(
    BuildContext context,
    WidgetRef ref,
    ProviderBase<AsyncValue<List<SendAssetFeeOptionModel>>> feeOptionsProvider,
  ) {
    ref.listen(feeOptionsProvider, (prev, next) {
      if (prev?.error?.runtimeType == next.error.runtimeType) return;

      if (next.hasError) {
        final error = next.error;
        AquaModalSheet.show(
          context,
          copiedToClipboardText: context.loc.copiedToClipboard,
          icon: AquaIcon.warning(color: Colors.white),
          iconVariant: AquaRingedIconVariant.warning,
          title: context.loc.somethingWentWrong,
          message: error is ExceptionLocalized
              ? error.toLocalizedString(context)
              : context.loc.errorWhilePreparingFeeOptions,
          primaryButtonText: context.loc.tryAgain,
          onPrimaryButtonTap: () {
            context.pop(); // Close the modal
            ref
                .read(sendFlowStepProvider.notifier)
                .setStep(SendFlowStep.amount);
          },
          secondaryButtonText: context.loc.commonContactSupport,
          onSecondaryButtonTap: () => context.push(HelpSupportScreen.routeName),
          colors: context.aquaColors,
        );
      }
    });
  }
}
