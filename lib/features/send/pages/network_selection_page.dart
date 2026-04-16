import 'package:aqua/common/exceptions/selection_unavailable_exception.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart' hide AssetIds;

class NetworkSelectionPage extends HookConsumerWidget {
  static const routeName = '/networkSelectionPage';

  const NetworkSelectionPage({
    super.key,
    required this.args,
    required this.goToStep,
  });

  final ValueNotifier<SendAssetArguments> args;
  final void Function(SendFlowStep) goToStep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final input = ref.watch(sendAssetInputStateProvider(args.value));
    final ambiguousAssets = input.valueOrNull?.ambiguousAssets ?? [];

    final flatAssets = useMemoized(() {
      final result = <AssetUiModel, List<AssetUiModel>>{};
      for (final asset in ambiguousAssets) {
        result[asset.toUiModel()] = <AssetUiModel>[];
      }
      return result.withSelectorSubtitles(context, AquaAssetSelectorType.send);
    }, [ambiguousAssets, context]);

    final handleDismiss = useCallback(() {
      if (context.mounted) {
        goToStep(SendFlowStep.address);
      }
    }, [goToStep]);

    ref.listen(sendAssetInputStateProvider(args.value), (prev, next) {
      next.maybeWhen(
        error: (error, _) {
          if (error is SelectionUnavailableException && context.mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AquaModalSheet.show(
                context,
                icon: AquaIcon.warning(color: Colors.white),
                iconVariant: AquaRingedIconVariant.warning,
                title: context.loc.somethingWentWrong,
                message: error.toLocalizedString(context),
                primaryButtonText: context.loc.goBack,
                onPrimaryButtonTap: () {
                  if (context.mounted) {
                    context.pop();
                    handleDismiss();
                  }
                },
                secondaryButtonText: context.loc.commonContactSupport,
                onSecondaryButtonTap: () =>
                    context.push(HelpSupportScreen.routeName),
                colors: context.aquaColors,
                copiedToClipboardText: context.loc.copiedToClipboard,
              ).then((_) => handleDismiss());
            });
          }
        },
        orElse: () {},
      );
    });

    final handleAssetSelection = useCallback((String? assetId) async {
      final notifier =
          ref.read(sendAssetInputStateProvider(args.value).notifier);

      final newArgs = await notifier.handleNetworkAssetSelection(
        assetId: assetId,
      );

      if (newArgs != null) {
        args.value = newArgs;
        goToStep(SendFlowStep.amount);
      }
    }, [args.value]);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AquaAssetSelector.send(
              assets: flatAssets,
              colors: context.aquaColors,
              type: AquaAssetSelectorType.send,
              trailingWidget: AquaIcon.chevronForward(
                color: context.aquaColors.textSecondary,
                size: 16,
              ),
              onAssetSelected: handleAssetSelection,
              tapForOptionsText: context.loc.tapForOptions,
            ),
          ),
        ],
      ),
    );
  }
}
