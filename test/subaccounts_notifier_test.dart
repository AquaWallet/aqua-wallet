import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/data/provider/network_frontend.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
import 'package:aqua/features/wallet/models/subaccounts.dart';
import 'package:aqua/features/wallet/providers/subaccounts_provider.dart';
import 'package:aqua/features/wallet/utils/derivation_path_utils.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'mocks/mocks.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(const GdkSubaccount(
      pointer: 0,
      name: 'Fallback Subaccount',
      type: GdkSubaccountTypeEnum.type_p2wpkh,
    ));
  });

  late MockBitcoinProvider mockBitcoinProvider;
  late MockLiquidProvider mockLiquidProvider;

  setUp(() {
    mockBitcoinProvider = MockBitcoinProvider();
    mockLiquidProvider = MockLiquidProvider();

    mockBitcoinProvider.mockGetTransactionsCall();
    mockLiquidProvider.mockGetTransactionsCall();
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        bitcoinProvider.overrideWithValue(mockBitcoinProvider),
        liquidProvider.overrideWithValue(mockLiquidProvider),
      ],
    );
  }

  group('SubaccountsNotifier', () {
    test('loadSubaccounts loads and combines subaccounts from both networks',
        () async {
      final bitcoinSubaccounts = [
        const GdkSubaccount(
            pointer: 1,
            name: 'Bitcoin 1',
            type: GdkSubaccountTypeEnum.type_p2wpkh),
        const GdkSubaccount(
            pointer: 2,
            name: 'Bitcoin 2',
            type: GdkSubaccountTypeEnum.type_p2wpkh),
      ];
      final liquidSubaccounts = [
        const GdkSubaccount(
            pointer: 1,
            name: 'Liquid 1',
            type: GdkSubaccountTypeEnum.type_p2wpkh),
        const GdkSubaccount(
            pointer: 2,
            name: 'Liquid 2',
            type: GdkSubaccountTypeEnum.type_p2wpkh),
      ];

      when(() => mockBitcoinProvider.getSubaccounts())
          .thenAnswer((_) async => bitcoinSubaccounts);
      when(() => mockLiquidProvider.getSubaccounts())
          .thenAnswer((_) async => liquidSubaccounts);

      final container = createContainer();
      await container.read(subaccountsProvider.notifier).loadSubaccounts();

      final state = container.read(subaccountsProvider);
      expect(state.value?.subaccounts.length, 4);
      expect(state.value?.subaccounts[0].networkType, NetworkType.bitcoin);
      expect(state.value?.subaccounts[2].networkType, NetworkType.liquid);
    });

    test('createNativeSegwitLiquidSubaccount creates a new Liquid subaccount',
        () async {
      const newSubaccount = GdkSubaccount(
          pointer: 3,
          name: "Liquid p2wpkh",
          type: GdkSubaccountTypeEnum.type_p2wpkh);

      when(() => mockLiquidProvider.createSubaccount(
          details: any(named: 'details'))).thenAnswer((_) async => null);
      when(() => mockBitcoinProvider.getSubaccounts())
          .thenAnswer((_) async => []);
      when(() => mockLiquidProvider.getSubaccounts())
          .thenAnswer((_) async => [newSubaccount]);

      final container = createContainer();
      await container
          .read(subaccountsProvider.notifier)
          .createNativeSegwitLiquidSubaccount();

      verify(() => mockLiquidProvider.createSubaccount(
          details: any(named: 'details'))).called(1);
      final state = container.read(subaccountsProvider);
      expect(state.value?.subaccounts.length, 1);
      expect(state.value?.subaccounts[0].subaccount.type,
          GdkSubaccountTypeEnum.type_p2wpkh);
      expect(state.value?.subaccounts[0].networkType, NetworkType.liquid);
    });

    test(
        'createAccountSubaccount creates a subaccount with correct derivation path',
        () async {
      const newSubaccount = GdkSubaccount(
          pointer: 3,
          name: "Account 1",
          type: GdkSubaccountTypeEnum.type_p2wpkh,
          userPath: [2147483732, 2147483648, 2147483648]); // 84'/0'/0'

      when(() => mockBitcoinProvider.createSubaccount(
          details: any(named: 'details'))).thenAnswer((_) async => null);
      when(() => mockBitcoinProvider.getSubaccounts())
          .thenAnswer((_) async => [newSubaccount]);
      when(() => mockLiquidProvider.getSubaccounts())
          .thenAnswer((_) async => []);

      final container = createContainer();
      await container
          .read(subaccountsProvider.notifier)
          .createAccountSubaccount(networkType: NetworkType.bitcoin);

      verify(() => mockBitcoinProvider.createSubaccount(
          details: any(named: 'details'))).called(1);
      final state = container.read(subaccountsProvider);
      expect(state.value?.subaccounts.length, 1);
      expect(state.value?.subaccounts[0].subaccount.userPath,
          [2147483732, 2147483648, 2147483648]);
      expect(state.value?.subaccounts[0].networkType, NetworkType.bitcoin);
    });

    test('createAccountSubaccount increments account index correctly',
        () async {
      final existingSubaccounts = [
        const GdkSubaccount(
            pointer: 1,
            name: "Account 1",
            type: GdkSubaccountTypeEnum.type_p2wpkh,
            userPath: [2147483732, 2147483648, 2147483648]), // 84'/0'/0'
        const GdkSubaccount(
            pointer: 2,
            name: "Account 2",
            type: GdkSubaccountTypeEnum.type_p2wpkh,
            userPath: [2147483732, 2147483648, 2147483649]), // 84'/0'/1'
      ];

      const newSubaccount = GdkSubaccount(
          pointer: 3,
          name: "Account 3",
          type: GdkSubaccountTypeEnum.type_p2wpkh,
          userPath: [2147483732, 2147483648, 2147483650]); // 84'/0'/2'

      when(() => mockBitcoinProvider.createSubaccount(
          details: any(named: 'details'))).thenAnswer((_) async => null);
      when(() => mockBitcoinProvider.getSubaccounts())
          .thenAnswer((_) async => [...existingSubaccounts, newSubaccount]);
      when(() => mockLiquidProvider.getSubaccounts())
          .thenAnswer((_) async => []);

      final container = createContainer();
      container.read(subaccountsProvider.notifier).state = AsyncValue.data(
          Subaccounts(
              subaccounts: existingSubaccounts
                  .map((s) => Subaccount(
                      subaccount: s, networkType: NetworkType.bitcoin))
                  .toList()));

      await container
          .read(subaccountsProvider.notifier)
          .createAccountSubaccount(networkType: NetworkType.bitcoin);

      verify(() => mockBitcoinProvider.createSubaccount(
          details: any(named: 'details'))).called(1);
      final state = container.read(subaccountsProvider);
      expect(state.value?.subaccounts.length, 3);
      expect(state.value?.subaccounts.last.subaccount.userPath,
          [2147483732, 2147483648, 2147483650]);
      expect(state.value?.subaccounts.last.subaccount.name, "Account 3");
    });
  });

  group('DerivationPathUtils', () {
    test('formatDerivationPath formats path correctly', () {
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147483648, 2147483648]),
          "m/84/0/0");
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483697, 2147483649, 2147483648]),
          "m/49/1/0");
      expect(DerivationPathUtils.formatDerivationPath(null),
          "m (No derivation path)");
    });

    test('formatDerivationPath handles different network types correctly', () {
      // Bitcoin Mainnet
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147483648, 2147483648]),
          "m/84/0/0");
      // Bitcoin Testnet
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147483649, 2147483648]),
          "m/84/1/0");
      // Liquid
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147485424, 2147483648]),
          "m/84/1776/0");
      // Liquid Testnet (assuming it uses the same coin type as Bitcoin Testnet)
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147483649, 2147483648]),
          "m/84/1/0");
    });

    test('formatDerivationPath handles different account types correctly', () {
      // Legacy (BIP44)
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483692, 2147483648, 2147483648]),
          "m/44/0/0");
      // SegWit (BIP49)
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483697, 2147483648, 2147483648]),
          "m/49/0/0");
      // Native SegWit (BIP84)
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147483648, 2147483648]),
          "m/84/0/0");
    });

    test('formatDerivationPath handles large account numbers correctly', () {
      expect(
          DerivationPathUtils.formatDerivationPath(
              [2147483732, 2147483648, 2147483648 + 1000000]),
          "m/84/0/1000000");
    });

    test('getCoinTypeForNetwork returns correct coin types', () {
      expect(DerivationPathUtils.getCoinTypeForNetwork(NetworkType.bitcoin), 0);
      expect(
          DerivationPathUtils.getCoinTypeForNetwork(NetworkType.bitcoinTestnet),
          1);
      expect(
          DerivationPathUtils.getCoinTypeForNetwork(NetworkType.liquid), 1776);
      expect(
          DerivationPathUtils.getCoinTypeForNetwork(NetworkType.liquidTestnet),
          1);
    });

    test('getPurposeForSubaccountType returns correct purposes', () {
      expect(
          DerivationPathUtils.getPurposeForSubaccountType(
              GdkSubaccountTypeEnum.type_p2pkh),
          44);
      expect(
          DerivationPathUtils.getPurposeForSubaccountType(
              GdkSubaccountTypeEnum.type_p2sh_p2wpkh),
          49);
      expect(
          DerivationPathUtils.getPurposeForSubaccountType(
              GdkSubaccountTypeEnum.type_p2wpkh),
          84);
    });

    test('hardenIndex and unhardenIndex work correctly', () {
      expect(DerivationPathUtils.hardenIndex(0), 0x80000000);
      expect(DerivationPathUtils.hardenIndex(1), 0x80000001);
      expect(DerivationPathUtils.unhardenIndex(0x80000000), 0);
      expect(DerivationPathUtils.unhardenIndex(0x80000001), 1);
    });

    test('isHardened correctly identifies hardened indices', () {
      expect(DerivationPathUtils.isHardened(0x80000000), true);
      expect(DerivationPathUtils.isHardened(0x80000001), true);
      expect(DerivationPathUtils.isHardened(0), false);
      expect(DerivationPathUtils.isHardened(1), false);
    });
  });

  test('getNextAccountIndex returns correct next index', () {
    final container = createContainer();
    final notifier = container.read(subaccountsProvider.notifier);
    final existingSubaccounts = [
      Subaccount(
          subaccount: GdkSubaccount(userPath: [
            DerivationPathUtils.hardenIndex(84),
            DerivationPathUtils.hardenIndex(0),
            DerivationPathUtils.hardenIndex(0)
          ]),
          networkType: NetworkType.bitcoin),
      Subaccount(
          subaccount: GdkSubaccount(userPath: [
            DerivationPathUtils.hardenIndex(84),
            DerivationPathUtils.hardenIndex(0),
            DerivationPathUtils.hardenIndex(1)
          ]),
          networkType: NetworkType.bitcoin),
    ];
    notifier.state =
        AsyncValue.data(Subaccounts(subaccounts: existingSubaccounts));

    expect(
        notifier.getNextAccountIndex(
            NetworkType.bitcoin, GdkSubaccountTypeEnum.type_p2wpkh),
        2);
  });

  test('getNextAccountIndex returns correct next index', () {
    final container = createContainer();
    final notifier = container.read(subaccountsProvider.notifier);
    final existingSubaccounts = [
      const Subaccount(
          subaccount:
              GdkSubaccount(userPath: [2147483732, 2147483648, 2147483648]),
          networkType: NetworkType.bitcoin),
      const Subaccount(
          subaccount:
              GdkSubaccount(userPath: [2147483732, 2147483648, 2147483649]),
          networkType: NetworkType.bitcoin),
    ];
    notifier.state =
        AsyncValue.data(Subaccounts(subaccounts: existingSubaccounts));

    expect(
        notifier.getNextAccountIndex(
            NetworkType.bitcoin, GdkSubaccountTypeEnum.type_p2wpkh),
        2);
  });
}
