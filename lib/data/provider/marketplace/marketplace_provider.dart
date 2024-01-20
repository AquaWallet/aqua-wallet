import 'package:flutter_riverpod/flutter_riverpod.dart';

final marketplaceProvider = Provider.autoDispose<MarketplaceProvider>((ref) {
  return MarketplaceProvider(ref);
});

class MarketplaceProvider {
  MarketplaceProvider(this._ref) {
    _ref.onDispose(() {});
  }

  final AutoDisposeProviderRef _ref;
}
