import 'package:coin_cz/data/models/gdk_models.dart';
import 'package:coin_cz/data/provider/network_frontend.dart';

enum DerivPathPurpose {
  bip44(44),
  bip49(49),
  bip84(84);

  final int value;
  const DerivPathPurpose(this.value);

  GdkSubaccountTypeEnum get gdkSubaccountType {
    switch (this) {
      case DerivPathPurpose.bip44:
        return GdkSubaccountTypeEnum.type_p2pkh;
      case DerivPathPurpose.bip49:
        return GdkSubaccountTypeEnum.type_p2sh_p2wpkh;
      case DerivPathPurpose.bip84:
        return GdkSubaccountTypeEnum.type_p2wpkh;
    }
  }

  static DerivPathPurpose fromGdkSubaccountType(GdkSubaccountTypeEnum type) {
    switch (type) {
      case GdkSubaccountTypeEnum.type_p2pkh:
        return DerivPathPurpose.bip44;
      case GdkSubaccountTypeEnum.type_p2sh_p2wpkh:
        return DerivPathPurpose.bip49;
      case GdkSubaccountTypeEnum.type_p2wpkh:
        return DerivPathPurpose.bip84;
      default:
        throw Exception('Unsupported GDK subaccount type');
    }
  }
}

enum DerivPathLevel {
  purpose(0),
  coinType(1),
  account(2),
  change(3),
  addressIndex(4);

  final int level;
  const DerivPathLevel(this.level);
}

class DerivationPathUtils {
  // ignore: constant_identifier_names
  static const int HARDENED_BIT = 0x80000000;

  static int hardenIndex(int index) {
    return index | HARDENED_BIT;
  }

  static int unhardenIndex(int index) {
    return index & ~HARDENED_BIT;
  }

  static bool isHardened(int index) {
    return (index & HARDENED_BIT) != 0;
  }

  static DerivPathPurpose getPurposeFromUserPath(List<int> userPath) {
    if (userPath.isEmpty) {
      throw Exception('Invalid user path');
    }
    final purposeValue = userPath[0] & ~0x80000000; // Remove hardened bit
    return DerivPathPurpose.values.firstWhere(
      (p) => p.index == purposeValue,
      orElse: () => throw Exception('Unsupported purpose: $purposeValue'),
    );
  }

  static int getAccountFromUserPath(List<int> userPath) {
    if (userPath.length < 3) {
      throw Exception('Invalid user path');
    }
    return userPath[2] & ~0x80000000; // Remove hardened bit
  }

  static int getPurposeForSubaccountType(GdkSubaccountTypeEnum type) {
    switch (type) {
      case GdkSubaccountTypeEnum.type_p2pkh:
        return 44;
      case GdkSubaccountTypeEnum.type_p2sh_p2wpkh:
        return 49;
      case GdkSubaccountTypeEnum.type_p2wpkh:
        return 84;
      default:
        throw Exception('Unsupported subaccount type for derivation path');
    }
  }

  static int getCoinTypeForNetwork(NetworkType networkType) {
    switch (networkType) {
      case NetworkType.bitcoin:
        return 0;
      case NetworkType.bitcoinTestnet:
        return 1;
      case NetworkType.liquid:
        return 1776;
      case NetworkType.liquidTestnet:
        return 1; // liquid testnet uses the same coin type as Bitcoin testnet
      default:
        throw Exception('Unsupported network type');
    }
  }

  static String formatDerivationPath(List<int>? userPath) {
    if (userPath == null || userPath.isEmpty) {
      return "m (No derivation path)";
    }
    return "m/${userPath.map((index) => unhardenIndex(index)).join('/')}";
  }
}
