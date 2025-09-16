import 'package:coin_cz/data/provider/network_frontend.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:coin_cz/data/models/gdk_models.dart';

part 'subaccount.freezed.dart';
part 'subaccount.g.dart';

@freezed
class Subaccount with _$Subaccount {
  const factory Subaccount({
    required GdkSubaccount subaccount,
    required NetworkType networkType,
  }) = _Subaccount;

  factory Subaccount.fromJson(Map<String, dynamic> json) =>
      _$SubaccountFromJson(json);
}

extension SubaccountExtension on Subaccount {
  // TODO: This a very simplified version of the export data.
  // For now we only have native segwit for Bitcoin and nested segwit for Liquid, but this will change will subaccounts.
  // We will have to come up with a much more thought out U/X flow for exporting/importing subaccounts, so users don't lose coins.
  String get exportData {
    switch (networkType) {
      case NetworkType.bitcoin:
      case NetworkType.bitcoinTestnet:
        return subaccount.slip132ExtendedPubkey ?? '';
      case NetworkType.liquid:
      case NetworkType.liquidTestnet:
        final descriptors = subaccount.coreDescriptors;
        if (descriptors == null || descriptors.length < 2) return '';
        // Combine both receive and change descriptors
        return '${descriptors[0]}\n${descriptors[1]}';
    }
  }

  String get blindingKey {
    final descriptors = subaccount.coreDescriptors;
    if (descriptors == null || descriptors.length < 2) return '';
    // Combine both receive and change descriptors
    final regex = RegExp(r'slip77\((.*?)\)');
    final match = regex.firstMatch(descriptors[0]);
    return match?.group(1) ?? '';
  }

  String get xpub {
    final descriptors = subaccount.coreDescriptors;
    if (descriptors == null || descriptors.length < 2) return '';
    // Combine both receive and change descriptors
    final RegExp pubKeyRegex = RegExp(r'[xyz]pub[^/]+');
    final match = pubKeyRegex.firstMatch(descriptors[0]);
    return match?.group(0) ?? '';
  }
}
