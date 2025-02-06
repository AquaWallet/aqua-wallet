import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/features/marketplace/models/models.dart';
import 'package:aqua/features/marketplace/providers/on_ramp_options_provider.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/user/user_hash_id_provider.dart';

final onRampSetupProvider = NotifierProvider<OnRampSetupNotifier,
    Map<OnRampIntegrationType, OnRampIntegrationHandler>>(
  OnRampSetupNotifier.new,
);

abstract class OnRampIntegrationHandler {
  Future<String> getIntegrationUrl(OnRampIntegration integration);
}

class DefaultIntegrationHandler implements OnRampIntegrationHandler {
  final OnRampOptionsNotifier _optionsNotifier;

  DefaultIntegrationHandler(this._optionsNotifier);

  @override
  Future<String> getIntegrationUrl(OnRampIntegration integration) async {
    final uri = await _optionsNotifier.formattedUri(integration);
    return uri.toString();
  }
}

class OnRampSetupNotifier
    extends Notifier<Map<OnRampIntegrationType, OnRampIntegrationHandler>> {
  @override
  Map<OnRampIntegrationType, OnRampIntegrationHandler> build() {
    return {};
  }

  void setupIntegrations(List<OnRampIntegration> integrations) {
    final handlers = <OnRampIntegrationType, OnRampIntegrationHandler>{};

    for (final integration in integrations) {
      switch (integration.type) {
        case OnRampIntegrationType.btcDirect:
          handlers[integration.type] = BTCDirectIntegrationHandler(
            btcDirectService: ref.read(btcDirectApiServiceProvider
                as ProviderListenable<BTCDirectApiService>),
            bitcoinProvider: ref.read(bitcoinProvider),
            getUserHashId: () => ref.read(userHashIdProvider.future),
          );
        default:
          handlers[integration.type] = DefaultIntegrationHandler(
            ref.read(onRampOptionsProvider.notifier),
          );
      }
    }

    state = handlers;
  }

  Future<String> getIntegrationUrl(OnRampIntegration integration) async {
    final handler = state[integration.type] ??
        DefaultIntegrationHandler(
          ref.read(onRampOptionsProvider.notifier),
        );
    return handler.getIntegrationUrl(integration);
  }
}
