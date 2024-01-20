import 'package:aqua/features/shared/shared.dart';
import 'package:rxdart/rxdart.dart';

enum WalletTabs {
  wallet,
  marketplace,
  settings,
}

final homeProvider =
    Provider.autoDispose<_HomeProvider>((ref) => _HomeProvider(ref));

class _HomeProvider {
  _HomeProvider(this._ref) {
    _ref.onDispose(() {
      _selectedBottomTabSubject.close();
    });
  }

  final AutoDisposeProviderRef _ref;

  Stream<bool> _contentVisibility() =>
      Stream.value(true).delay(const Duration(milliseconds: 500));

  final BehaviorSubject<WalletTabs> _selectedBottomTabSubject =
      BehaviorSubject.seeded(WalletTabs.wallet);
  void selectTab(int index) {
    _selectedBottomTabSubject.add(WalletTabs.values.elementAt(index));
  }
}

//ANCHOR - Content Visibility

final _homeContentVisibilityStreamProvider =
    StreamProvider.autoDispose<bool>((ref) async* {
  yield* ref.watch(homeProvider)._contentVisibility();
});

final homeContentVisibilityProvider = Provider.autoDispose<bool>((ref) {
  return ref.watch(_homeContentVisibilityStreamProvider).asData?.value ?? false;
});

//ANCHOR - Tabs

final _homeSelectedBottomTabStreamProvider =
    StreamProvider.autoDispose<WalletTabs>((ref) async* {
  yield* ref.watch(homeProvider)._selectedBottomTabSubject;
});

final homeSelectedBottomTabProvider = Provider.autoDispose<WalletTabs>((ref) {
  return ref.watch(_homeSelectedBottomTabStreamProvider).asData?.value ??
      WalletTabs.wallet;
});

class HomeUnableToDecryptBiometricException implements Exception {}
