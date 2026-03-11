import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class LiquidFeeSelector extends HookConsumerWidget
    with FeeOptionsErrorHandlerMixin {
  const LiquidFeeSelector({
    super.key,
    required this.args,
  });

  final SendAssetArguments args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feeOptionsProvider = useMemoized(
      () => sendAssetFeeOptionsProvider(args),
      [args],
    );
    final feeOptionsAsync = ref.watch(feeOptionsProvider);
    final feeOptions = feeOptionsAsync.asData?.value ?? [];

    final lbtcFeeOption = useMemoized(
      () => feeOptions
          .whereType<LiquidSendAssetFeeOptionModel>()
          .map((e) => e.fee)
          .whereType<LbtcLiquidFeeModel>()
          .firstOrNull,
      [feeOptions.length],
    );
    final usdtFeeOption = useMemoized(
      () => feeOptions
          .whereType<LiquidSendAssetFeeOptionModel>()
          .map((e) => e.fee)
          .whereType<UsdtLiquidFeeModel>()
          .firstOrNull,
      [feeOptions.length],
    );

    final inputProvider = useMemoized(
      () => sendAssetInputStateProvider(args),
      [args],
    );
    final input = ref.watch(inputProvider).value!;

    // Automatically enable an available fee option
    useEffect(() {
      if (input.fee != null) return null;
      //NOTE: First because we want to prioritize L-BTC over USDt for L-BTC send fees
      final availableFeeOption = feeOptions
          .whereType<LiquidSendAssetFeeOptionModel>()
          .where((e) => e.fee.isEnabled)
          .firstWhereOrNull((e) => e.fee.availableForFeePayment);

      if (availableFeeOption != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(inputProvider.notifier).updateFeeAsset(availableFeeOption);
        });
      }

      return null;
    }, [feeOptions]);

    // Upon screen enter, refresh the fiat rates if the fee options are empty
    //due to an error
    useEffect(() {
      if (!feeOptionsAsync.isLoading &&
          feeOptionsAsync.hasError &&
          feeOptions.isEmpty) {
        ref.invalidate(fiatRatesProvider);
      }
      return null;
    });

    setupFeeOptionsErrorHandler(context, ref, feeOptionsProvider);

    return Row(
      children: [
        //ANCHOR: Lbtc fee selector
        if (lbtcFeeOption != null) ...{
          Expanded(
            child: _SelectionItem(
                item: lbtcFeeOption,
                isEnabled: lbtcFeeOption.isEnabled,
                isSelected: input.isLiquidFeeAsset,
                onPressed: () {
                  if (!input.isLiquidFeeAsset) {
                    ref
                        .read(inputProvider.notifier)
                        .updateFeeAsset(lbtcFeeOption.toFeeOptionModel());
                  }
                }),
          ),
        },
        if (lbtcFeeOption != null && usdtFeeOption != null) ...[
          const SizedBox(width: 16),
        ],
        if (usdtFeeOption != null) ...{
          //ANCHOR: Usdt fee selector
          Expanded(
            child: _SelectionItem(
                item: usdtFeeOption,
                isEnabled: usdtFeeOption.isEnabled,
                isSelected: input.isUsdtFeeAsset,
                onPressed: () {
                  if (!input.isUsdtFeeAsset) {
                    ref
                        .read(inputProvider.notifier)
                        .updateFeeAsset(usdtFeeOption.toFeeOptionModel());
                  }
                }),
          ),
        } else ...{
          //NOTE - We still need to occupy the space, otherwise the lone LBTC fee tile would be too big
          const Expanded(child: SizedBox.shrink()),
        },
      ],
    );
  }
}

class _SelectionItem extends StatelessWidget {
  const _SelectionItem({
    required this.item,
    required this.isSelected,
    required this.isEnabled,
    required this.onPressed,
  });

  final LiquidFeeModel item;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final asset = item.map(
      lbtc: (_) => Asset.lbtc(),
      usdt: (_) => Asset.usdtLiquid(),
    );

    return AspectRatio(
      aspectRatio: 1.0,
      child: AquaFeeTile(
        title: asset.displayName,
        icon: asset.logoUrl.isValidUrl
            ? AquaAssetIcon.fromUrl(
                url: asset.logoUrl,
                size: 18,
              )
            : AquaAssetIcon.fromAssetId(
                assetId: asset.id,
                size: 18,
              ),
        amountCrypto: item.feeDisplay,
        amountFiat: item.maybeMap(
          lbtc: (model) => model.fiatFeeDisplay,
          orElse: () => '',
        ),
        colors: context.aquaColors,
        isSelected: isSelected,
        onTap: onPressed,
        isEnabled: isEnabled,
      ),
    );
  }
}
