import 'package:aqua/features/address_validator/address_validator.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = CustomLogger(FeatureFlag.send);

/// Provider that automatically detects lightning invoice to LBTC address swaps
/// by listening to the send asset input provider changes
final lightningInvoiceToLbtcSwapProvider = AsyncNotifierProvider.family
    .autoDispose<LightningInvoiceToLbtcSwapNotifier, bool, SendAssetArguments>(
  LightningInvoiceToLbtcSwapNotifier.new,
);

class LightningInvoiceToLbtcSwapNotifier
    extends AutoDisposeFamilyAsyncNotifier<bool, SendAssetArguments> {
  @override
  Future<bool> build(SendAssetArguments arg) async {
    ref.listen(sendAssetInputStateProvider(arg), (previous, next) {
      if (previous?.value == null || next.value == null) return;

      final prevAddress = previous!.value!.addressFieldText;
      final newAddress = next.value!.addressFieldText;
      _detectSwap(prevAddress, newAddress);
    });

    return false;
  }

  Future<void> _detectSwap(String? prevAddress, String? newAddress) async {
    if (prevAddress == null ||
        newAddress == null ||
        prevAddress == newAddress) {
      return;
    }

    try {
      final parser = ref.read(addressParserProvider);
      final wasLightningInvoice = parser.isLightningInvoice(input: prevAddress);
      final isLbtcAddress = await parser.isValidAddressForAsset(
        asset: Asset.lbtc(),
        address: newAddress,
        accountForCompatibleAssets: false,
      );
      final isAquaLightningAddressSwap = wasLightningInvoice && isLbtcAddress;

      _logger.debug('[LnInvoiceToLbtcSwap] Change: '
          'wasLightningInvoice=$wasLightningInvoice, '
          'isLbtcAddress=$isLbtcAddress, '
          'isSwap=$isAquaLightningAddressSwap');

      state = AsyncValue.data(isAquaLightningAddressSwap);
    } catch (e, stackTrace) {
      _logger.error('[LnInvoiceToLbtcSwap] Error', e, stackTrace);
      state = const AsyncValue.data(false);
    }
  }
}
