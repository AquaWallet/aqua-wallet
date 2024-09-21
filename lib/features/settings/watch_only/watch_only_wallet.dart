import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/network_frontend.dart';

part 'watch_only_wallet.freezed.dart';

@freezed
class WatchOnlyWallet with _$WatchOnlyWallet {
  const WatchOnlyWallet._();

  const factory WatchOnlyWallet({
    required GdkSubaccount subaccount,
    required NetworkType networkType,
  }) = _WatchOnlyWallet;

  // NOTE: This a very simplified version of the export data.
  // For now we only have native segwit for Bitcoin and nested segwit for Liquid, but this will change will subaccounts.
  String get exportData {
    switch (networkType) {
      case NetworkType.bitcoin:
        return subaccount.slip132ExtendedPubkey ?? '';
      case NetworkType.liquid:
        // NOTE: GDK returns a list of coreDescriptors, but we only need the first one. The second one is the change/internal descriptor.
        return subaccount.coreDescriptors?.firstOrNull ?? '';
    }
  }
}
