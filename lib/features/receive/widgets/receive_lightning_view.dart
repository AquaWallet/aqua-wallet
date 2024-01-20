import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/features/receive/pages/models/models.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ReceiveLightningView extends ConsumerWidget {
  final Asset asset;
  final ReceiveBoltzUIState boltzUIState;
  final String? errorMessage;
  final BoltzState? state;
  final num? loadingPct;
  final WebViewController _controller;
  final String? invoice;

  const ReceiveLightningView({
    Key? key,
    required this.asset,
    required this.boltzUIState,
    this.errorMessage,
    this.invoice,
    this.loadingPct,
    required this.state,
    required WebViewController controller,
  })  : _controller = controller,
        super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (boltzUIState == ReceiveBoltzUIState.enterAmount) {
      return Column(
        children: [
          SizedBox(height: 40.h),
          ReceiveAmountInputWidget(asset: asset),
          SizedBox(height: 21.h),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 28.w),
            child: Column(children: [
              CustomError(errorMessage: errorMessage),
            ]),
          ),
        ],
      );
    }

    if (invoice == null) {
      return Column(
        children: [
          SizedBox(height: 24.h),
          SizedBox(
              height: 300.h,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      state == BoltzState.loading
                          ? AppLocalizations.of(context)!
                              .receiveLightningViewLoadingStatusMessage
                          : AppLocalizations.of(context)!
                              .receiveLightningViewGeneratingStatusMessage,
                      style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(
                    height: 20.h,
                  ),
                  const CircularProgressIndicator(),
                ],
              ))
        ],
      );
    }

    return Column(
      children: [
        SizedBox(height: 24.h),
        BoxShadowCard(
          elevation: 4,
          color: Theme.of(context).colorScheme.surface,
          margin: EdgeInsets.symmetric(horizontal: 28.w),
          borderRadius: BorderRadius.circular(12.r),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 24.h),
                //ANCHOR - QR Code
                ReceiveAssetQrCode(
                    assetAddress: invoice!,
                    assetId: Asset.lightning().id,
                    assetIconUrl: Asset.lightning().logoUrl),
                SizedBox(height: 21.h),
                //ANCHOR - Copy Address Button
                ReceiveAssetCopyAddressButton(
                  address: invoice!,
                ),
                SizedBox(height: 21.h),
              ],
            ),
          ),
        ),
        SizedBox(
          height: 0.h,
          child: WebViewWidget(controller: _controller),
        ),
      ],
    );
  }
}
