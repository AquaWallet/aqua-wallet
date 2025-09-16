import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/receive/providers/providers.dart';
import 'package:coin_cz/features/receive/widgets/widgets.dart';
import 'package:coin_cz/features/settings/manage_assets/models/assets.dart';
import 'package:coin_cz/features/receive/keys/receive_screen_keys.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAmountInputSheet extends HookConsumerWidget {
  const ReceiveAmountInputSheet({
    super.key,
    required this.asset,
    required this.onCancel,
    required this.onConfirm,
    required this.onChanged,
    this.controller,
    this.errorText,
    this.isConfirmEnabled = true,
  });

  final Asset asset;
  final Function onCancel;
  final Function(String) onConfirm;
  final Function(String) onChanged;
  final TextEditingController? controller;
  final String? errorText;
  final bool isConfirmEnabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountEntered =
        useState<String?>(ref.read(receiveAssetAmountProvider));

    final textController =
        controller ?? useTextEditingController(text: amountEntered.value);
    textController.addListener(() {
      final newValue = textController.text;
      amountEntered.value = newValue;
      onChanged(newValue);
    });

    // fiat entry toggle
    final isFiatToggled = ref.watch(amountCurrencyProvider) != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 21.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18.0),
          //ANCHOR - Title
          Text(
            context.loc.setAmount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.0,
                ),
          ),
          const SizedBox(height: 19.0),
          //ANCHOR - Amount Input
          Container(
            decoration: Theme.of(context).solidBorderDecoration,
            child: AmountInputField(
              asset: asset,
              controller: textController,
              isFiatToggled: isFiatToggled,
            ),
          ),
          if (errorText != null) ...[
            const SizedBox(height: 4.0),
            Text(
              errorText!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],

          const SizedBox(height: 18.0),
          //ANCHOR - Confirm Button
          SizedBox(
            width: double.maxFinite,
            child: AquaElevatedButton(
              key: ReceiveAssetKeys.receiveAssetConfirmButton,
              onPressed: (amountEntered.value == null ||
                      amountEntered.value == '' ||
                      !isConfirmEnabled)
                  ? null
                  : () {
                      ref.read(receiveAssetAmountProvider.notifier).state =
                          amountEntered.value;
                      onConfirm(amountEntered.value!);
                    },
              child: Text(
                context.loc.confirm,
              ),
            ),
          ),
          //ANCHOR - Cancel Button
          if (asset.isLightning) ...[
            const SizedBox(height: 20.0),
            SizedBox(
              width: double.maxFinite,
              child: AquaElevatedButton(
                onPressed: () {
                  onCancel();
                  context.pop();
                },
                child: Text(
                  context.loc.cancel,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
