import 'package:aqua/data/provider/app_links/app_link.dart';
import 'package:aqua/features/account/models/api_models.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'stored_wallet.freezed.dart';
part 'stored_wallet.g.dart';

/// Maximum number of wallets a user can create
const int kMaxWallets = 21;

@freezed
class StoredWallet with _$StoredWallet {
  const factory StoredWallet({
    required String id,
    required String name,
    required DateTime createdAt,
    String? description,
    ProfileResponse? profileResponse,
    AuthTokenResponse? authToken,
    SamRockAppLink? samRockAppLink,
  }) = _StoredWallet;

  factory StoredWallet.fromJson(Map<String, dynamic> json) =>
      _$StoredWalletFromJson(json);
}

extension StoredWalletFormatting on StoredWallet {
  /// Returns the wallet ID (fingerprint) formatted with spaces for better readability
  String get formattedFingerprint {
    // If fingerprint is 8 characters (standard BIP32 fingerprint length)
    if (id.length == 8) {
      return '${id.substring(0, 4)} ${id.substring(4)}';
    }
    // For other lengths, add a space every 4 characters
    final buffer = StringBuffer();
    for (var i = 0; i < id.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(id[i]);
    }
    return buffer.toString();
  }
}

/// Extension for wallet name validation
//TODO: Need to revise validation rules with UX
extension WalletNameValidation on String {
  /// Validates a wallet name
  /// Returns null if valid, or an error message if invalid
  String? validateWalletName() {
    if (isEmpty) {
      return 'Wallet name cannot be empty';
    }

    if (length < 3) {
      return 'Wallet name must be at least 3 characters';
    }

    if (length > 30) {
      return 'Wallet name must be less than 30 characters';
    }

    // Check for invalid characters
    if (contains(RegExp(r'[^\w\s\-\.]'))) {
      return 'Wallet name contains invalid characters';
    }

    return null; // Valid
  }
}
