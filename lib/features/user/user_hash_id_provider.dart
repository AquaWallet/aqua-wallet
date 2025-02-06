import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/models/gdk_models.dart';

/// Generate a user ID based on the hash ofthe BIP84 (Native SegWit) subaccount zpub
class UserHashIdNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    final bitcoinSubaccounts =
        await ref.read(bitcoinProvider.select((p) => p.getSubaccounts()));

    // Get the BIP84 (Native SegWit) subaccount
    final bip84Subaccount = bitcoinSubaccounts?.firstWhere(
      (subaccount) => subaccount.type == GdkSubaccountTypeEnum.type_p2wpkh,
      orElse: () => throw StateError('No BIP84 subaccount found'),
    );

    if (bip84Subaccount == null) {
      throw StateError('Bitcoin subaccounts not available');
    }

    final zpub = bip84Subaccount.slip132ExtendedPubkey;
    if (zpub == null) {
      throw StateError('No zpub available for BIP84 subaccount');
    }

    // Generate user ID by hashing the zpub
    final bytes = utf8.encode(zpub);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

final userHashIdProvider =
    AsyncNotifierProvider<UserHashIdNotifier, String>(() {
  return UserHashIdNotifier();
});
