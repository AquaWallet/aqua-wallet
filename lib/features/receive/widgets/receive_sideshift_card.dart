import 'package:aqua/common/common.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:aqua/common/dialogs/dialog_manager.dart';

class ReceiveSideshiftCard extends HookConsumerWidget {
  const ReceiveSideshiftCard({
    super.key,
    required this.asset,
  });

  final Asset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(sideshiftReceiveProvider(asset));

    final handleSideshiftError = useCallback((Object ex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final error = ex is ExceptionLocalized
            ? ex.toLocalizedString(context)
            : ex is OrderException && (ex.message?.isNotEmpty ?? false)
                ? ex.message!
                : context.loc.sideshiftGenericError;
        logger.e('[Receive][Sideshift] Error: $error');

        final alertModel = CustomAlertDialogUiModel(
          title: context.loc.genericErrorMessage,
          subtitle: error,
          buttonTitle: context.loc.ok,
          onButtonPressed: () {
            Navigator.of(context).pop();
          },
        );
        DialogManager().showDialog(context, alertModel);
      });
    }, [context]);

    useEffect(() {
      order.whenData((o) {
        logger.d("[Receive][SideShift] In Progress Order: ${o?.id}");
        logger.d("[Receive][SideShift] Deposit Address: ${o?.depositAddress}");
        logger.d("[Receive][SideShift] Settle Address: ${o?.settleAddress}");
      });

      order.whenOrNull(
        error: (error, _) => handleSideshiftError(error),
      );

      return null;
    }, [order]);

    final enableShareButton = order.hasValue;
    final address = order.valueOrNull?.depositAddress ?? '';

    return Column(
      children: [
        SizedBox(height: 24.h),
        ReceiveAssetAddressQrCard(
          asset: asset,
          address: address,
          sideshiftOrder: order.valueOrNull,
        ),
        //ANCHOR - Sideshift Info Container
        SizedBox(height: 21.h),
        ReceiveShiftInformation(
          order: order.valueOrNull,
          assetNetwork: asset.usdtOption.networkLabel(context),
        ),
        SizedBox(height: 21.h),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          child: Row(
            children: [
              //ANCHOR - Share Button
              Flexible(
                flex: asset.shouldShowAmountInputOnReceive ? 0 : 1,
                child: ReceiveAssetAddressShareButton(
                  isEnabled: enableShareButton,
                  isExpanded: !asset.shouldShowAmountInputOnReceive,
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
