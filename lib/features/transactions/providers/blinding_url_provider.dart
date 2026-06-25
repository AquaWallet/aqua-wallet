import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:lwk/lwk.dart' show TxOutSecrets;

final blindingUrlProvider = Provider<BlindingUrlHelper>(
  (ref) => BlindingUrlHelper(),
);

class BlindingUrlHelper {
  String _formatQuadruple(
    Object value,
    String assetId,
    String amountBlinder,
    String assetBlinder,
  ) =>
      '$value,$assetId,$amountBlinder,$assetBlinder';

  Iterable<String> gdkInOutsToBlindingStrings(
    List<GdkTransactionInOut> inOuts,
  ) {
    return inOuts
        .where((io) => io.amountBlinder != null && io.assetBlinder != null)
        .map((io) => _formatQuadruple(
              io.satoshi ?? 0,
              io.assetId!,
              io.amountBlinder!,
              io.assetBlinder!,
            ));
  }

  String txOutSecretsToBlindingData(List<TxOutSecrets> secrets) {
    return secrets
        .map((s) => _formatQuadruple(s.value, s.asset, s.valueBf, s.assetBf))
        .join(',');
  }

  String buildBlindingUrl({
    required String txhash,
    required bool isLiquid,
    List<GdkTransactionInOut>? inputs,
    List<GdkTransactionInOut>? outputs,
    String? storedBlindingData,
  }) {
    if (!isLiquid) return '';

    final parts = <String>[
      if (inputs?.isNotEmpty ?? false) ...gdkInOutsToBlindingStrings(inputs!),
      if (outputs?.isNotEmpty ?? false) ...gdkInOutsToBlindingStrings(outputs!),
      if (storedBlindingData != null && storedBlindingData.isNotEmpty)
        storedBlindingData,
    ];

    if (parts.isEmpty) return '';
    return '$txhash#blinded=${parts.join(',')}';
  }
}
