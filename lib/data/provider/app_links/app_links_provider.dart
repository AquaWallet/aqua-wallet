import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appLinkProvider = Provider<AppLinkProvider>((ref) {
  return AppLinkProvider();
});

class AppLinkProvider {
  static const _linkHostApp = 'app.sideswap.io';
  static const _linkHostAqua = 'aqua.sideswap.io';
  static const _linkPath = '/swap/';
  static const _linkParameterOrderId = 'order_id';
  static const _linkParameterSendAsset = 'send_asset';
  static const _linkParameterRecvAsset = 'recv_asset';
  static const _linkParameterSendAmount = 'send_amount';
  static const _linkParameterRecvAmount = 'recv_amount';
  static const _linkParameterUploadUrl = 'upload_url';

  static const _samRockPath = '/samrock';
  static const _samRockSetupParam = 'setup';
  static const _samRockOtpParam = 'otp';

  AppLinkProvider();

  AppLink parseAppLinkUri(Uri uri) {
    try {
      if (uri.path.contains(_samRockPath)) {
        return _parseSamRockLink(uri);
      }

      if ((_linkHostApp == uri.host || _linkHostAqua == uri.host) &&
          _linkPath == uri.path) {
        return _parseSwapLink(uri);
      }

      throw ArgumentError();
    } catch (err) {
      throw AppLinkProviderInvalidLinkException();
    }
  }

  AppLink _parseSamRockLink(Uri uri) {
    final setup = uri.queryParameters[_samRockSetupParam];
    if (setup == null || setup.isEmpty) {
      throw ArgumentError();
    }

    final otp = uri.queryParameters[_samRockOtpParam];
    if (otp == null || otp.isEmpty) {
      throw ArgumentError();
    }

    final setupChains =
        setup.split(',').where((chain) => chain.isNotEmpty).toList();
    if (setupChains.isEmpty) {
      throw ArgumentError();
    }

    return AppLink.samRock(
      setupChains: setupChains,
      otp: otp,
      uploadUrl: uri.toString(),
    );
  }

  AppLink _parseSwapLink(Uri uri) {
    final orderId = uri.queryParameters[_linkParameterOrderId];
    if (orderId == null || orderId.isEmpty) {
      throw ArgumentError();
    }
    final sendAsset = uri.queryParameters[_linkParameterSendAsset];
    if (sendAsset == null || sendAsset.isEmpty) {
      throw ArgumentError();
    }
    final recvAsset = uri.queryParameters[_linkParameterRecvAsset];
    if (recvAsset == null || recvAsset.isEmpty) {
      throw ArgumentError();
    }
    final sendAmount = uri.queryParameters[_linkParameterSendAmount];
    if (sendAmount == null || sendAmount.isEmpty) {
      throw ArgumentError();
    }
    final sendAmountValue = int.parse(sendAmount);
    final recvAmount = uri.queryParameters[_linkParameterRecvAmount];
    if (recvAmount == null || recvAmount.isEmpty) {
      throw ArgumentError();
    }
    final recvAmountValue = int.parse(recvAmount);
    final uploadUrl = uri.queryParameters[_linkParameterUploadUrl];
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw ArgumentError();
    }

    return AppLink.swap(
      orderId: orderId,
      sendAsset: sendAsset,
      sendAmount: sendAmountValue,
      recvAsset: recvAsset,
      recvAmount: recvAmountValue,
      uploadUrl: uploadUrl,
    );
  }
}

class AppLinkProviderInvalidLinkException implements Exception {}
