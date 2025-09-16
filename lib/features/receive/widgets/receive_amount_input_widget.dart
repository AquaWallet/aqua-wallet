import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/receive/pages/models/receive_asset_extensions.dart';
import 'package:coin_cz/features/receive/providers/providers.dart';
import 'package:coin_cz/features/receive/widgets/widgets.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ReceiveAmountInputWidget extends HookConsumerWidget {
  const ReceiveAmountInputWidget({super.key, required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // amount
    final amountEntered = ref.watch(receiveAssetAmountProvider);

    // amount input controller
    final controller = useTextEditingController(text: amountEntered);
    controller.addListener(() {
      ref.read(receiveAssetAmountProvider.notifier).state = controller.text;
    });

    // fiat entry toggle
    final isFiatToggled = ref.watch(amountCurrencyProvider) != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        BoxShadowCard(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          margin: const EdgeInsets.symmetric(horizontal: 28.0),
          borderRadius: BorderRadius.circular(12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const SizedBox(height: 24.0),

                //ANCHOR - Title
                Text(
                  context.loc.setAmount,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 20.0,
                      ),
                ),
                const SizedBox(height: 24.0),

                //ANCHOR - Amount Input Field
                Container(
                  decoration: Theme.of(context).solidBorderDecoration,
                  child: AmountInputField(
                    asset: asset,
                    controller: controller,
                    isFiatToggled: isFiatToggled,
                  ),
                ),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18.0),

        //ANCHOR - Conversion
        if (asset.shouldShowConversionOnReceive) ...[
          ReceiveConversionWidget(asset: asset),
        ],
        const SizedBox(height: 18.0),
        if (asset.isLightning) ...[
          BoltzFeeWidget(amountEntered: amountEntered),
        ],
        const SizedBox(height: 18.0),
      ],
    );
  }
}

class ReceiveConversionWidget extends ConsumerWidget {
  final Asset asset;
  final String? amountStr;

  const ReceiveConversionWidget(
      {super.key, required this.asset, this.amountStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedFiatCurrency = ref.watch(amountCurrencyProvider);
    final isFiatCurrency = selectedFiatCurrency != null;
    final satsStr =
        isFiatCurrency && (asset.isLightning || asset.isLBTC || asset.isBTC)
            ? ' sats'
            : '';
    return ref
        .watch(receiveAssetAmountConversionDisplayProvider(
            (asset, selectedFiatCurrency, amountStr)))
        .when(
          data: (value) => Text('≈ $value$satsStr'),
          loading: () => const Skeletonizer(enabled: true, child: Text('≈ 0')),
          error: (error, stack) => const Text('≈ 0'),
        );
  }
}
