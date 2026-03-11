import 'package:aqua/config/router/router.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/transactions/transactions.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ui_components/components/account_item/account_item.dart';
import 'package:ui_components/components/asset_selector/asset_selector.dart';
import 'package:ui_components/models/models.dart';

import '../helpers.dart';
import '../mocks/mocks.dart';

class MockGoRouter extends Mock implements GoRouter {}

class FakeBuildContext extends Fake implements BuildContext {}

class MockManageAssetsNotifier extends Mock implements ManageAssetsProvider {
  List<Asset> _curatedAssets = [];
  List<Asset> _activeAltUSDts = [];
  @override
  List<Asset> get curatedAssets => _curatedAssets;

  List<Asset> get activeAltUSDts => _activeAltUSDts;

  void setCuratedAssets(List<Asset> assets) {
    _curatedAssets = assets;
  }

  void setActiveAltUSDts(List<Asset> assets) {
    _activeAltUSDts = assets;
  }
}

void main() {
  group('AssetNetworkSelectionScreen', () {
    late MockUserPreferencesNotifier mockPrefsProvider;
    late MockManageAssetsNotifier mockManageAssetsNotifier;
    late MockGoRouter mockRouter;
    late ProviderContainer container;

    setUpAll(() {
      SharedPreferences.setMockInitialValues({});
      registerFallbackValue(Asset.btc());
      registerFallbackValue(FakeBuildContext());
    });

    setUp(() {
      mockPrefsProvider = MockUserPreferencesNotifier();
      mockManageAssetsNotifier = MockManageAssetsNotifier();
      mockRouter = MockGoRouter();

      mockPrefsProvider.mockGetDarkModeCall(false);
      mockPrefsProvider.mockGetNonLiquidUsdtWarningDisplayedCall(false);
      mockPrefsProvider.mockGetLightningWarningDisplayedCall(false);
      mockPrefsProvider.mockMarkNonLiquidUsdtWarningDisplayedCall();
      mockPrefsProvider.mockMarkLightningWarningDisplayedCall();

      container = createContainer(
        overrides: [
          prefsProvider.overrideWith((_) => mockPrefsProvider),
          routerProvider.overrideWithValue(mockRouter),
          manageAssetsProvider.overrideWithValue(mockManageAssetsNotifier),
          activeAltUSDtsProvider.overrideWithValue([]),
          receiveAssetsListProvider.overrideWithValue({}),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestableWidget({Asset? filterAsset}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: const [
            ...AppLocalizations.localizationsDelegates,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: AssetNetworkSelectionScreen(filterAsset: filterAsset),
          ),
        ),
      );
    }

    group('Asset Filtering Logic', () {
      testWidgets('shows 2 AquaAssetSelector widgets when filterAsset is LBTC',
          (tester) async {
        final lbtcAsset = Asset.lbtc();
        final lightningAsset = Asset(
          id: 'lightning',
          name: 'Bitcoin Lightning',
          ticker: 'BTC',
          logoUrl: '',
          isLiquid: false,
          isLBTC: false,
          isUSDt: false,
        );

        // Create the proper data structure that receiveAssetsListProvider would return
        final lbtcUiModel = lbtcAsset.toUiModel();
        final lightningUiModel = lightningAsset.toUiModel();

        final mockAssetsMap = {
          lbtcUiModel: <AssetUiModel>[],
          lightningUiModel: <AssetUiModel>[],
        };

        mockManageAssetsNotifier.setCuratedAssets([lbtcAsset]);
        mockManageAssetsNotifier.setActiveAltUSDts([]);

        container = createContainer(
          overrides: [
            prefsProvider.overrideWith((_) => mockPrefsProvider),
            routerProvider.overrideWithValue(mockRouter),
            manageAssetsProvider.overrideWithValue(mockManageAssetsNotifier),
            activeAltUSDtsProvider.overrideWithValue([]),
            receiveAssetsListProvider.overrideWithValue(mockAssetsMap),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(filterAsset: lbtcAsset));

        await tester.pump();

        expect(find.byType(AssetNetworkSelectionScreen), findsOneWidget);
        expect(find.byType(AquaAssetSelector), findsOneWidget);
        expect(find.byType(AquaAccountItem), findsNWidgets(2));
      });

      testWidgets(
          'shows multiple AquaAssetSelector widgets when filterAsset is USDT',
          (tester) async {
        final usdtLiquidAsset = Asset.usdtLiquid();
        final usdtEthAsset = Asset.usdtEth();
        final usdtTrxAsset = Asset.usdtTrx();
        final usdtBepAsset = Asset.usdtBep();

        // Create the proper data structure for USDT
        final usdtTetherUiModel =
            usdtLiquidAsset.copyWith(id: 'usdt-tether').toUiModel();
        final liquidUsdtUiModel =
            usdtLiquidAsset.toUiModel(name: 'Liquid USDt');
        final ethUsdtUiModel = usdtEthAsset.toUiModel();
        final trxUsdtUiModel = usdtTrxAsset.toUiModel();
        final bepUsdtUiModel = usdtBepAsset.toUiModel();

        final mockAssetsMap = {
          usdtTetherUiModel: [
            liquidUsdtUiModel,
            ethUsdtUiModel,
            trxUsdtUiModel,
            bepUsdtUiModel
          ],
        };

        mockManageAssetsNotifier.setCuratedAssets([usdtLiquidAsset]);
        mockManageAssetsNotifier
            .setActiveAltUSDts([usdtEthAsset, usdtTrxAsset, usdtBepAsset]);

        container = createContainer(
          overrides: [
            prefsProvider.overrideWith((_) => mockPrefsProvider),
            routerProvider.overrideWithValue(mockRouter),
            manageAssetsProvider.overrideWithValue(mockManageAssetsNotifier),
            activeAltUSDtsProvider
                .overrideWithValue([usdtEthAsset, usdtTrxAsset, usdtBepAsset]),
            receiveAssetsListProvider.overrideWithValue(mockAssetsMap),
          ],
        );

        await tester
            .pumpWidget(buildTestableWidget(filterAsset: usdtLiquidAsset));

        await tester.pump();

        expect(find.byType(AssetNetworkSelectionScreen), findsOneWidget);
        expect(find.byType(AquaAssetSelector), findsOneWidget);
        expect(find.byType(AquaAccountItem), findsNWidgets(4));
      });

      testWidgets('shows 1 AquaAssetSelector widget when filterAsset is BTC',
          (tester) async {
        final btcAsset = Asset.btc();

        // Create the proper data structure for BTC
        final btcUiModel = btcAsset.toUiModel();

        final mockAssetsMap = {
          btcUiModel: <AssetUiModel>[],
        };

        mockManageAssetsNotifier.setCuratedAssets([btcAsset]);
        mockManageAssetsNotifier.setActiveAltUSDts([]);

        container = createContainer(
          overrides: [
            prefsProvider.overrideWith((_) => mockPrefsProvider),
            routerProvider.overrideWithValue(mockRouter),
            manageAssetsProvider.overrideWithValue(mockManageAssetsNotifier),
            activeAltUSDtsProvider.overrideWithValue([]),
            receiveAssetsListProvider.overrideWithValue(mockAssetsMap),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(filterAsset: btcAsset));

        await tester.pump();

        expect(find.byType(AssetNetworkSelectionScreen), findsOneWidget);
        expect(find.byType(AquaAssetSelector), findsOneWidget);
        expect(find.byType(AquaAccountItem), findsOneWidget);
      });

      testWidgets(
          'shows 1 AquaAssetSelector widget when filterAsset is any other asset',
          (tester) async {
        final ethAsset = Asset(
          id: 'ethereum',
          name: 'Ethereum',
          ticker: 'ETH',
          logoUrl: '',
          isLiquid: false,
          isLBTC: false,
          isUSDt: false,
        );

        // Create the proper data structure for ETH
        final ethUiModel = ethAsset.toUiModel();

        final mockAssetsMap = {
          ethUiModel: <AssetUiModel>[],
        };

        mockManageAssetsNotifier.setCuratedAssets([ethAsset]);
        mockManageAssetsNotifier.setActiveAltUSDts([]);

        container = createContainer(
          overrides: [
            prefsProvider.overrideWith((_) => mockPrefsProvider),
            routerProvider.overrideWithValue(mockRouter),
            manageAssetsProvider.overrideWithValue(mockManageAssetsNotifier),
            activeAltUSDtsProvider.overrideWithValue([]),
            receiveAssetsListProvider.overrideWithValue(mockAssetsMap),
          ],
        );

        await tester.pumpWidget(buildTestableWidget(filterAsset: ethAsset));

        await tester.pump();

        expect(find.byType(AssetNetworkSelectionScreen), findsOneWidget);
        expect(find.byType(AquaAssetSelector), findsOneWidget);
        expect(find.byType(AquaAccountItem), findsOneWidget);
      });
    });
  });
}
