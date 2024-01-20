import 'package:aqua/features/shared/widgets/asset_icon.dart';
import 'package:aqua/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReceiveAssetQrCode extends StatelessWidget {
  const ReceiveAssetQrCode({
    super.key,
    required this.assetAddress,
    required this.assetId,
    required this.assetIconUrl,
  });

  final String assetAddress;
  final String assetId;
  final String assetIconUrl;

  @override
  Widget build(BuildContext context) {
    logger.d("[LN] assetAddress: $assetAddress");
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 9.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: SizedBox.square(
        child: assetAddress.isEmpty
            ? Center(
                child: SizedBox(
                  width: 60.r,
                  height: 60.r,
                  child: AssetIcon(
                    assetId: assetId,
                    assetLogoUrl: assetIconUrl,
                    size: 60.r,
                  ),
                ),
              )
            : Stack(
                alignment: Alignment.center,
                children: [
                  QrImage(
                    data: assetAddress,
                    version: QrVersions.auto,
                    embeddedImage: null,
                    embeddedImageStyle: QrEmbeddedImageStyle(
                      size: Size(45.r, 45.r),
                    ),
                  ),
                  AssetIcon(
                    assetId: assetId,
                    assetLogoUrl: assetIconUrl,
                    size: 60.r,
                  ),
                ],
              ),
      ),
    );
  }
}
