import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/lightning_address/services/services.dart';
import 'package:aqua/features/shared/shared.dart';

final lnUsernameUpdateProductProvider = AsyncNotifierProvider.autoDispose<
    LnUsernameUpdateProductNotifier,
    LiquidWalletProduct?>(LnUsernameUpdateProductNotifier.new);

class LnUsernameUpdateProductNotifier
    extends AutoDisposeAsyncNotifier<LiquidWalletProduct?> {
  @override
  Future<LiquidWalletProduct?> build() async {
    final api = ref.read(jan3ApiLightningAddressesProvider);
    final response = await api.getProducts(
      LiquidWalletProductType.lnUsernameUpdate.apiValue,
    );
    final list = response.body;
    return list != null && list.isNotEmpty ? list.first : null;
  }
}
