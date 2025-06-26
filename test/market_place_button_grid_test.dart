import 'package:aqua/features/backup/providers/backup_reminder_provider.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:aqua/features/marketplace/widgets/error_retry_button.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_button.dart';
import 'package:aqua/features/marketplace/widgets/marketplace_button_grid.dart';
import 'package:aqua/features/marketplace/providers/enabled_services_provider.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAssetsNotifier extends AssetsNotifier {
  @override
  Future<List<Asset>> build() async {
    return [];
  }
}

class FakeEnabledServicesNotifier extends EnabledServicesTypesNotifier {
  final List<MarketplaceServiceAvailability> services;
  final bool throwError;
  final Duration delay;

  FakeEnabledServicesNotifier({
    required this.services,
    this.throwError = false,
    this.delay = Duration.zero,
  }) : super();

  @override
  Future<List<MarketplaceServiceAvailability>> build() async {
    await Future.delayed(delay);
    if (throwError) {
      throw Exception('Error fetching services');
    }
    return services;
  }
}

List<Override> defaultOverrides({Override? enabledServicesOverride}) {
  return [
    assetsProvider.overrideWith(() => FakeAssetsNotifier()),
    hasTransactedProvider.overrideWith((_) => Future.value(false)),
    if (enabledServicesOverride != null) enabledServicesOverride,
  ];
}

const shortDelay = Duration(milliseconds: 50);
const longDelay = Duration(milliseconds: 250);

void main() {
  Widget buildTestableWidget(
      {Widget child = const MarketplaceButtonGrid(),
      List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ], supportedLocales: const [
        Locale('en', ''), // English
      ], home: Scaffold(body: child)),
    );
  }

  testWidgets('shows loading indicator', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        overrides: [
          enabledServicesTypesProvider.overrideWith(() =>
              FakeEnabledServicesNotifier(services: [], delay: longDelay)),
          ...defaultOverrides()
        ],
      ),
    );

    await tester.pump(shortDelay);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pump(longDelay);
  });

  testWidgets('shows error message when expecting', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(overrides: [
        enabledServicesTypesProvider.overrideWith(
          () => FakeEnabledServicesNotifier(
            services: [],
            throwError: true,
          ),
        ),
        ...defaultOverrides()
      ]),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorRetryButton), findsOneWidget);
  });
  testWidgets('shows empty message when no services enabled', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        overrides: [
          enabledServicesTypesProvider
              .overrideWith(() => FakeEnabledServicesNotifier(services: [])),
          ...defaultOverrides()
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ErrorRetryButton), findsOneWidget);
  });

  testWidgets('shows enabled services as buttons', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        overrides: [
          enabledServicesTypesProvider
              .overrideWith(() => FakeEnabledServicesNotifier(services: [
                    const MarketplaceServiceAvailability(
                      type: MarketplaceServiceType.swaps,
                      isEnabled: true,
                    ),
                    const MarketplaceServiceAvailability(
                      type: MarketplaceServiceType.buyBitcoin,
                      isEnabled: true,
                    ),
                  ])),
          ...defaultOverrides()
        ],
      ),
    );
    await tester.pumpAndSettle();
    // Check for MarketplaceButton widgets
    expect(find.byType(MarketplaceButton), findsNWidgets(2));
  });

  testWidgets('Takes into account if they are enabled', (tester) async {
    await tester.pumpWidget(buildTestableWidget(
      overrides: [
        enabledServicesTypesProvider
            .overrideWith(() => FakeEnabledServicesNotifier(services: [
                  const MarketplaceServiceAvailability(
                    type: MarketplaceServiceType.swaps,
                    isEnabled: true,
                  ),
                  const MarketplaceServiceAvailability(
                    type: MarketplaceServiceType.giftCards,
                    isEnabled: false,
                  ),
                ])),
        ...defaultOverrides()
      ],
    ));
    await tester.pumpAndSettle();
    expect(find.byType(MarketplaceButton), findsOne);
  });
}
