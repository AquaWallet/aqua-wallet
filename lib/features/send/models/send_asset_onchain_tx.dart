import 'package:aqua/data/models/gdk_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_asset_onchain_tx.freezed.dart';

@freezed
class SendAssetOnchainTx with _$SendAssetOnchainTx {
  /// `gdkTx` is used for most onchain transactions
  const factory SendAssetOnchainTx.gdkTx(GdkNewTransactionReply gdkTx) = _GdkTx;

  /// `gdkPsbt` is used for taxi sends, where we need to send a psbt to the rust-elements library
  const factory SendAssetOnchainTx.gdkPsbt(GdkSignPsbtResult gdkPsbt) =
      _GdkPsbt;
}

extension SendAssetOnchainTxExtension on SendAssetOnchainTx {
  /// Unwrap and return the tx hex
  String? get transactionHex {
    return maybeMap(
      gdkTx: (tx) => tx.gdkTx.transaction,
      gdkPsbt: (tx) => tx.gdkPsbt.psbt,
      orElse: () => null,
    );
  }

  /// Unwrap and return the tx hash
  String? get transactionHash {
    return maybeMap(
      gdkTx: (tx) => tx.gdkTx.txhash,
      gdkPsbt: (tx) =>
          null, // TODO: If we need the psbt hash, we can calculate it here from the tx hex
      orElse: () => null,
    );
  }
}
