import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_cz/features/shared/providers/env_provider.dart'; // ← Asegúrate de importar EnvConfig
import 'package:coin_cz/config/constants/secrets.dart';

final btcDirectEnvConfigProvider = Provider<EnvConfig>((ref) {
  final isSandbox = true; // Cambia a false para producción

  if (isSandbox) {
    return EnvConfig(
      apiUrl: 'https://api-sandbox.btcdirect.eu', // ← Usa apiUrl, no baseUrl
      apiKey: Secrets.kBtcDirectSandboxApiKey,
      username: Secrets.kBtcDirectSandboxUsername,
      password: Secrets.kBtcDirectSandboxPassword,
      secret: Secrets.kBtcDirectSandboxSecret,
    );
  } else {
    return EnvConfig(
      apiUrl: 'https://api.btcdirect.eu',
      apiKey: Secrets.kBtcDirectProdApiKey,
      username: Secrets.kBtcDirectProdUsername,
      password: Secrets.kBtcDirectProdPassword,
      secret: Secrets.kBtcDirectProdSecret,
    );
  }
});