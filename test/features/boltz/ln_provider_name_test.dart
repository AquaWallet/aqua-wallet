import 'package:aqua/config/constants/lightning_providers.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/feature_flags/models/feature_flags_models.dart';
import 'package:boltz/boltz.dart';
import 'package:flutter_test/flutter_test.dart';

BoltzSwapDbModel _swap({String? boltzUrl}) => BoltzSwapDbModel(
      boltzId: 'swap-1',
      kind: SwapType.submarine,
      network: Chain.liquid,
      hashlock: 'hashlock',
      receiverPubkey: 'receiver',
      senderPubkey: 'sender',
      invoice: 'lnbc1',
      outAmount: 50000,
      blindingKey: 'blinding',
      locktime: 100,
      scriptAddress: 'address',
      boltzUrl: boltzUrl,
    );

void main() {
  group('lnProviderNameForApiUrl', () {
    test('names Boltz for the mainnet API URL it used to serve', () {
      expect(
        lnProviderNameForApiUrl('https://api.boltz.exchange/v2'),
        legacyLnProviderName,
      );
    });

    test('names Boltz for the testnet API URL too', () {
      expect(
        lnProviderNameForApiUrl('https://api.testnet.boltz.exchange/v2'),
        legacyLnProviderName,
      );
    });

    test('names Boltz for a v0 swap, which stored no API URL', () {
      expect(lnProviderNameForApiUrl(null), legacyLnProviderName);
      expect(lnProviderNameForApiUrl(''), legacyLnProviderName);
    });

    test('names the current provider for any other host', () {
      expect(
        lnProviderNameForApiUrl('https://api.example.com/v2'),
        currentLnProviderName,
      );
    });

    test('names the configured provider when the caller passes one', () {
      expect(
        lnProviderNameForApiUrl(
          'https://api.example.com/v2',
          currentName: 'SatsRouting',
        ),
        'SatsRouting',
      );
      // A retired host keeps its frozen name whatever the config says.
      expect(
        lnProviderNameForApiUrl(
          'https://api.boltz.exchange/v2',
          currentName: 'SatsRouting',
        ),
        legacyLnProviderName,
      );
    });

    test('still names Boltz when the stored URL will not parse', () {
      expect(
        lnProviderNameForApiUrl('api.boltz.exchange/v2'),
        legacyLnProviderName,
      );
    });
  });

  group('BoltzSwapDbModel.displayProviderName', () {
    test('reads the provider from the URL stored with the swap', () {
      expect(
        _swap(boltzUrl: 'https://api.boltz.exchange/v2').displayProviderName(),
        legacyLnProviderName,
      );
      expect(
        _swap(boltzUrl: 'https://api.example.com/v2').displayProviderName(),
        currentLnProviderName,
      );
      expect(_swap().displayProviderName(), legacyLnProviderName);
    });

    test('names the configured provider for a non-retired host', () {
      expect(
        _swap(boltzUrl: 'https://api.example.com/v2')
            .displayProviderName(currentName: 'SatsRouting'),
        'SatsRouting',
      );
    });
  });

  group('SetupConfig.lnProviderNameOrNull', () {
    const config = SetupConfig(
      date: '2026-08-24',
      baseUrls: {
        BoltzBaseUrlKeys.submarineProviderName: 'SatsRouting',
        BoltzBaseUrlKeys.reverseProviderName: 'Indra',
      },
    );

    test('reads the name key for each swap type', () {
      expect(config.lnProviderNameOrNull(SwapType.submarine), 'SatsRouting');
      expect(config.lnProviderNameOrNull(SwapType.reverse), 'Indra');
    });

    test('returns null when the config carries no name', () {
      const empty = SetupConfig(date: '2026-08-24');
      expect(empty.lnProviderNameOrNull(SwapType.submarine), isNull);
      const blank = SetupConfig(
        date: '2026-08-24',
        baseUrls: {BoltzBaseUrlKeys.submarineProviderName: ''},
      );
      expect(blank.lnProviderNameOrNull(SwapType.submarine), isNull);
      expect(config.lnProviderNameOrNull(SwapType.chain), isNull);
    });
  });
}
