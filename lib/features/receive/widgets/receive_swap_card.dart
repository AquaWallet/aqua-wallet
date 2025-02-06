import 'package:aqua/common/common.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/widgets/usdt_swap_min_max_panel.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:aqua/utils/utils.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/config/config.dart';

//TODO: Polygon DOESN'T work for Changelly, need to remove if Changelly
class ReceiveSwapCard extends HookConsumerWidget {
  const ReceiveSwapCard({
    super.key,
    required this.deliverAsset,
    this.swapPair,
  });

  final Asset deliverAsset;
  final SwapPair? swapPair;

  Widget _buildErrorContent(BuildContext context, String errorMessage) {
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final alertModel = CustomAlertDialogUiModel(
          title: context.loc.somethingWentWrong,
          subtitle: errorMessage,
          buttonTitle: context.loc.ok,
          onButtonPressed: () {
            DialogManager().dismissDialog(context);
          },
        );
        DialogManager().showDialog(context, alertModel);
      });
      return null;
    }, []);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 100.0),
      alignment: Alignment.center,
      child: Text(
        context.loc.somethingWentWrong,
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (swapPair == null) {
      return _buildErrorContent(
          context, context.loc.swapServiceGeneralError(''));
    }

    final args = useMemoized(() => SwapArgs(pair: swapPair!), [swapPair]);
    final swapOrder = ref.watch(swapOrderProvider(args));
    final swapOrderNotifier = ref.read(swapOrderProvider(args).notifier);

    // create order
    final createSwapOrder = useCallback((String? amount) async {
      final swapAsset = SwapAssetExt.fromAsset(deliverAsset);
      final receiveAddress =
          (await ref.read(liquidProvider).getReceiveAddress())?.address;
      final request = SwapOrderRequest(
        receiveAddress: receiveAddress,
        from: swapAsset,
        to: SwapAssetExt.usdtLiquid,
        type: SwapOrderType.variable,
        amount: amount != null ? Decimal.parse(amount) : null,
      );
      await swapOrderNotifier.createReceiveOrder(request);
    }, [deliverAsset, swapOrderNotifier]);

    // amount (if needed)
    final needsAmount = swapOrderNotifier.needsAmountOnReceive;
    final showAmountSheet = useState(needsAmount);
    useEffect(() {
      if (!needsAmount) {
        createSwapOrder(null);
        return;
      }

      if (showAmountSheet.value && needsAmount) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: true,
            useSafeArea: true,
            backgroundColor: Theme.of(context).colors.background,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30.0),
                topRight: Radius.circular(30.0),
              ),
            ),
            builder: (_) => _AmountModalContent(
              asset: deliverAsset,
              swapPair: swapPair!,
              onAmountConfirmed: (amount) {
                showAmountSheet.value = false;
                createSwapOrder(amount);
              },
              onDismiss: () {
                showAmountSheet.value = false;
              },
            ),
          );
        });
      }
      return null;
    }, [showAmountSheet.value, needsAmount]);

    // main qr content
    final enableShareButton = swapOrder.hasValue;
    final address = swapOrder.valueOrNull?.order?.depositAddress ?? '';
    return swapOrder.when(
      data: (orderState) => orderState.order != null
          ? _SwapContent(
              order: orderState.order!,
              enableShareButton: enableShareButton,
              address: address,
            )
          : _LoadingContent(
              asset: deliverAsset, address: address, swapPair: swapPair),
      loading: () => _LoadingContent(
          asset: deliverAsset, address: address, swapPair: swapPair),
      error: (error, stackTrace) {
        final errorMessage =
            ((error as ExceptionLocalized?)?.toLocalizedString(context) ??
                    context.loc.swapServiceGeneralError(''))
                .toString();
        return _buildErrorContent(context, errorMessage);
      },
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({
    required this.asset,
    required this.address,
    this.swapPair,
  });

  final Asset asset;
  final String address;
  final SwapPair? swapPair;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24.0),
        ReceiveAssetAddressQrCard(
          asset: asset,
          address: address,
          swapOrder: null,
          swapPair: swapPair,
        ),
      ],
    );
  }
}

class _SwapContent extends StatelessWidget {
  const _SwapContent({
    required this.order,
    required this.enableShareButton,
    required this.address,
  });

  final SwapOrder order;
  final bool enableShareButton;
  final String address;

  @override
  Widget build(BuildContext context) {
    final deliverAsset = order.from.toAsset();
    final swapPair = SwapPair(
      from: order.from,
      to: order.to,
    );

    return Column(
      children: [
        const SizedBox(height: 24.0),
        ReceiveAssetAddressQrCard(
          asset: deliverAsset,
          address: address,
          swapOrder: order,
          swapPair: swapPair,
        ),
        const SizedBox(height: 21.0),
        ReceiveSwapInformation(
          order: order,
          deliverAssetNetwork: deliverAsset.usdtOption.networkLabel(context),
        ),
        const SizedBox(height: 21.0),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Row(
            children: [
              Flexible(
                flex: deliverAsset.shouldShowAmountInputOnReceive ? 0 : 1,
                child: ReceiveAssetAddressShareButton(
                  isEnabled: enableShareButton,
                  isExpanded: !deliverAsset.shouldShowAmountInputOnReceive,
                  address: address,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AmountModalContent extends HookConsumerWidget {
  const _AmountModalContent({
    required this.asset,
    required this.swapPair,
    required this.onAmountConfirmed,
    required this.onDismiss,
  });

  final Asset asset;
  final SwapPair swapPair;
  final Function(String amount) onAmountConfirmed;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final args = useMemoized(() => SwapArgs(pair: swapPair), [swapPair]);
    final rate = ref.watch(swapOrderProvider(args)).valueOrNull?.rate;

    final amountController = useTextEditingController();
    final amountError = useState<String?>(null);
    final isValidAmount = useState(false);

    final debouncer = useMemoized(() => Debouncer(milliseconds: 500));
    useEffect(() => debouncer.dispose, []);

    final validateAmount = useCallback((String amount) {
      try {
        final decimal = Decimal.parse(amount);
        if (rate != null) {
          final deliverAsset = asset.name;
          if (decimal < rate.min) {
            return context.loc.swapServiceMinAmountError(deliverAsset);
          }
          if (decimal > rate.max) {
            return context.loc.swapServiceMaxAmountError(deliverAsset);
          }
        }
        return null;
      } catch (e) {
        return context.loc.swapServiceAmountError;
      }
    }, [rate]);

    final onAmountChanged = useCallback((String amount) {
      if (amount.isEmpty) {
        amountError.value = null;
        isValidAmount.value = false;
        return;
      }

      debouncer.run(() {
        final error = validateAmount(amount);
        amountError.value = error;
        isValidAmount.value = error == null;
      });
    }, [validateAmount]);

    final onConfirm = useCallback((String amount) async {
      final error = validateAmount(amount);
      if (error != null) {
        amountError.value = error;
        isValidAmount.value = false;
        return;
      }
      isValidAmount.value = true;
      onAmountConfirmed(amount);
      context.pop(); // pop modal
    }, [validateAmount, onAmountConfirmed]);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ReceiveAmountInputSheet(
            asset: asset,
            controller: amountController,
            errorText: amountError.value,
            onCancel: onDismiss,
            onConfirm: onConfirm,
            onChanged: onAmountChanged,
            isConfirmEnabled: isValidAmount.value,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: USDtSwapMinMaxPanel(
              swapPair: swapPair,
            ),
          ),
          const SizedBox(height: 16.0),
        ],
      ),
    );
  }
}
