import 'package:freezed_annotation/freezed_annotation.dart';

part 'bip329_label_model.freezed.dart';
part 'bip329_label_model.g.dart';

enum BIP329Type { tx, address, pubkey, input, output, xpub }

/// Represents a single BIP329 label entry
/// See: https://github.com/bitcoin/bips/blob/master/bip-0329.mediawiki
@freezed
class Bip329Label with _$Bip329Label {
  const factory Bip329Label({
    /// The type of object being labeled.
    /// One of tx, addr, pubkey, input, output or xpub
    required BIP329Type type,

    /// Reference to the transaction, address, public key, input, output or extended public key
    required String ref,

    /// The label applied to the reference
    String? label,

    /// Optional key origin information referencing the wallet associated with the label
    String? origin,

    /// Optional key denoting if an output should be spendable by the wallet
    bool? spendable,
  }) = _Bip329Label;

  factory Bip329Label.fromJson(Map<String, dynamic> json) =>
      _$Bip329LabelFromJson(json);
}
