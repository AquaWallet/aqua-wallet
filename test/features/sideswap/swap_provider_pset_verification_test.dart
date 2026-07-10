import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks/mocks.dart';

class MockSideswapHttpProvider extends Mock implements SideswapHttpProvider {}

void main() {
  const sendAssetId = 'usdt-liquid-asset-id';
  const recvAssetId = 'lbtc-asset-id';

  // The user approves sending 10 units, receiving 5000...
  const approvedSendAmount = 10000000;
  const approvedRecvAmount = 5000;
  // ...but the wallet holds a single UTXO worth 50x the send amount.
  const oversizedUtxoValue = 500000000;

  // USDt -> L-BTC: send asset is not L-BTC, so it gets no fee allowance.
  const usdtToLbtc = SwapStartWebResult(
    orderId: 'order-1',
    sendAsset: sendAssetId,
    sendAmount: approvedSendAmount,
    recvAsset: recvAssetId,
    recvAmount: approvedRecvAmount,
    uploadUrl: 'https://api.sideswap.io/upload',
  );

  Asset assetWith(String id) =>
      Asset(id: id, name: id, ticker: id, logoUrl: '');

  // What the user selected/entered on the swap screen (deliver side edited).
  SideswapInputState approvedInput({
    String sendAsset = sendAssetId,
    String recvAsset = recvAssetId,
    int deliverSats = approvedSendAmount,
  }) =>
      SideswapInputState(
        assets: const [],
        deliverAsset: assetWith(sendAsset),
        receiveAsset: assetWith(recvAsset),
        deliverAmountSatoshi: deliverSats,
      );

  group('isTrustedSideswapUploadUrl', () {
    test('accepts HTTPS SideSwap hosts (incl. env subdomains)', () {
      expect(
          isTrustedSideswapUploadUrl('https://api.sideswap.io/swap'), isTrue);
      expect(isTrustedSideswapUploadUrl('https://api-testnet.sideswap.io/'),
          isTrue);
      expect(isTrustedSideswapUploadUrl('https://api-regtest.sideswap.io/'),
          isTrue);
      expect(isTrustedSideswapUploadUrl('https://sideswap.io/'), isTrue);
    });

    test('rejects non-HTTPS, look-alike, and malformed hosts', () {
      expect(isTrustedSideswapUploadUrl('http://api.sideswap.io/'), isFalse);
      expect(
          isTrustedSideswapUploadUrl('https://sideswap.io.evil.com/'), isFalse);
      expect(isTrustedSideswapUploadUrl('https://evilsideswap.io/'), isFalse);
      expect(isTrustedSideswapUploadUrl('https://notsideswap.io/'), isFalse);
      expect(isTrustedSideswapUploadUrl('not a url'), isFalse);
      expect(isTrustedSideswapUploadUrl(''), isFalse);
    });
  });

  group('isSwapPsetDeltaApproved', () {
    const otherAsset = 'some-other-asset-id';

    // L-BTC -> USDt: send asset IS L-BTC, so the fee comes out of the send side.
    const lbtcToUsdt = SwapStartWebResult(
      orderId: 'order-2',
      sendAsset: recvAssetId, // L-BTC
      sendAmount: approvedRecvAmount,
      recvAsset: sendAssetId, // USDt
      recvAmount: approvedSendAmount,
      uploadUrl: 'https://api.sideswap.io/upload',
    );

    bool approved(
      Map<String, int> walletDelta, {
      SwapStartWebResult order = usdtToLbtc,
      int fee = 0,
    }) =>
        isSwapPsetDeltaApproved(
          walletDelta: walletDelta,
          order: order,
          lbtcId: recvAssetId,
          fee: fee,
        );

    test('approves the exact approved net effect', () {
      expect(approved({recvAssetId: 5000, sendAssetId: -10000000}), isTrue);
    });

    test('approves receiving more than approved', () {
      expect(approved({recvAssetId: 6000, sendAssetId: -10000000}), isTrue);
    });

    test('approves spending less than approved', () {
      expect(approved({recvAssetId: 5000, sendAssetId: -9999000}), isTrue);
    });

    test('approves an L-BTC send debited by sendAmount + fee', () {
      expect(
        approved({recvAssetId: -5050, sendAssetId: 10000000},
            order: lbtcToUsdt, fee: 50),
        isTrue,
      );
    });

    test('rejects an empty delta (fail closed)', () {
      expect(approved({}), isFalse);
    });

    test('rejects a receive leg diverted to an attacker', () {
      expect(approved({recvAssetId: 0, sendAssetId: -10000000}), isFalse);
    });

    test('rejects receiving less than approved', () {
      expect(approved({recvAssetId: 4999, sendAssetId: -10000000}), isFalse);
    });

    test('rejects an over-sized UTXO drained with change withheld', () {
      expect(approved({recvAssetId: 5000, sendAssetId: -oversizedUtxoValue}),
          isFalse);
    });

    test('rejects spending an unrelated wallet asset', () {
      expect(
        approved({recvAssetId: 5000, sendAssetId: -10000000, otherAsset: -1}),
        isFalse,
      );
    });

    test('rejects an L-BTC send exceeding sendAmount + fee by 1', () {
      expect(
        approved({recvAssetId: -5051, sendAssetId: 10000000},
            order: lbtcToUsdt, fee: 50),
        isFalse,
      );
    });

    test('does not grant a fee allowance to a non-L-BTC send asset', () {
      expect(approved({recvAssetId: 5000, sendAssetId: -10000001}, fee: 50),
          isFalse);
    });
  });

  group('isSwapOrderApproved', () {
    test('approves an order matching the selected assets and entered amount',
        () {
      expect(isSwapOrderApproved(order: usdtToLbtc, input: approvedInput()),
          isTrue);
    });

    test('rejects sending more than the user entered', () {
      expect(
        isSwapOrderApproved(
            order: usdtToLbtc,
            input: approvedInput(deliverSats: approvedSendAmount - 1)),
        isFalse,
      );
    });

    test('rejects an asset substitution', () {
      expect(
        isSwapOrderApproved(
            order: usdtToLbtc,
            input: approvedInput(sendAsset: 'attacker-asset')),
        isFalse,
      );
    });

    test('rejects receiving less than the user entered (receive side)', () {
      final input = approvedInput().copyWith(
        userInputSide: SwapUserInputSide.receive,
        receiveAmountSatoshi: approvedRecvAmount + 1,
        deliverAmountSatoshi: 0,
      );
      expect(isSwapOrderApproved(order: usdtToLbtc, input: input), isFalse);
    });

    test('rejects when no amount is entered to anchor against (fail closed)',
        () {
      // Assets match, but neither side has a user-entered amount.
      expect(
        isSwapOrderApproved(
            order: usdtToLbtc, input: approvedInput(deliverSats: 0)),
        isFalse,
      );
    });
  });

  group('executeTransaction', () {
    setUpAll(() {
      registerFallbackValue(
          const GdkPsbtGetDetails(psbt: '', utxos: <Map<String, dynamic>>[]));
      registerFallbackValue(
          const GdkSignPsbtDetails(psbt: '', utxos: <Map<String, dynamic>>[]));
      registerFallbackValue(const HttpStartWebParams(
        orderId: '',
        inputs: <GdkCreatePsetInputs>[],
        recvAddr: '',
        changeAddr: '',
        sendAsset: '',
        sendAmount: 0,
        recvAsset: '',
        recvAmount: 0,
      ));
      registerFallbackValue(const SwapStartWebResult(
        orderId: '',
        sendAsset: '',
        sendAmount: 0,
        recvAsset: '',
        recvAmount: 0,
        uploadUrl: '',
      ));
      registerFallbackValue(Uri());
    });

    const walletReceiveAddr = 'WALLET_OWNED_RECEIVE_ADDR';
    const servicePset = 'SERVICE_BUILT_PSET_BASE64';
    const signedServicePset = 'SIGNED_PSET_BASE64';
    const submitId = 'submit-id-1';

    late ProviderContainer container;
    late MockLiquidProvider mockLiquid;
    late MockSideswapHttpProvider mockHttp;
    late MockFeatureFlagsProvider mockFlags;
    late MockManageAssetsProvider mockManageAssets;

    // A reply whose `satoshi` map is GDK's signed net effect on the wallet.
    GdkNewTransactionReply replyWithWalletNet(Map<String, int> net) =>
        GdkNewTransactionReply(fee: 49, satoshi: net);

    ProviderContainer makeContainer(SideswapInputState input) =>
        ProviderContainer(overrides: [
          liquidProvider.overrideWithValue(mockLiquid),
          sideswapHttpProvider.overrideWithValue(mockHttp),
          featureFlagsProvider.overrideWith((ref) => mockFlags),
          manageAssetsProvider.overrideWithValue(mockManageAssets),
          sideswapInputStateProvider
              .overrideWith((_) => MockSideswapInputStateNotifier(input)),
        ]);

    setUp(() {
      mockLiquid = MockLiquidProvider();
      mockHttp = MockSideswapHttpProvider();
      mockFlags = MockFeatureFlagsProvider();
      mockManageAssets = MockManageAssetsProvider();

      // Wallet holds ONE oversized send-asset UTXO (50x the approved amount).
      const oversizedUtxo = GdkUnspentOutputs(
        assetId: sendAssetId,
        satoshi: oversizedUtxoValue,
        txhash: 'oversized-utxo-txid',
        ptIdx: 0,
        assetBlinder: 'asset-blinder',
        amountBlinder: 'amount-blinder',
      );
      // NOTE: the inner list must be modifiable - executeTransaction sorts the
      // send-asset UTXOs in place.
      when(() => mockLiquid.getUnspentOutputs())
          .thenAnswer((_) async => GdkUnspentOutputsReply(unsentOutputs: {
                sendAssetId: List.of([oversizedUtxo]),
              }));

      // Wallet generates its own receive + change addresses (called twice).
      when(() => mockLiquid.getReceiveAddress()).thenAnswer((_) async =>
          const GdkReceiveAddressDetails(address: walletReceiveAddr));

      // The endpoint returns the PSET to verify + sign.
      when(() => mockHttp.httpStartWebParamsBody(any(), any(), any()))
          .thenAnswer((_) async => {
                'result': {'pset': servicePset, 'submit_id': submitId},
              });

      when(() => mockLiquid.signPsbt(any())).thenAnswer(
          (_) async => const GdkNewTransactionReply(psbt: signedServicePset));

      when(() => mockFlags.fakeBroadcastsEnabled).thenReturn(false);

      when(() => mockHttp.httpBodySign(any(), any(), any(), any()))
          .thenAnswer((_) async => {
                'result': {'status': 'ok'},
              });

      // Send asset (USDt) is not L-BTC, so no fee allowance applies to it.
      when(() => mockManageAssets.lbtcAsset).thenReturn(Asset.lbtc());

      container = makeContainer(approvedInput());
    });

    tearDown(() => container.dispose());

    test('rejects a tampered PSET and never signs or submits it', () async {
      // We DO receive the promised L-BTC, but the entire 500-unit USDt UTXO
      // leaves the wallet (no change) - far more than the approved sendAmount.
      when(() => mockLiquid.getDetailsPsbt(any()))
          .thenAnswer((_) async => replyWithWalletNet({
                recvAssetId: approvedRecvAmount,
                sendAssetId: -oversizedUtxoValue,
              }));

      final notifier = container.read(swapProvider.notifier);
      notifier
          .requestVerification(const SwapStartWebResponse(result: usdtToLbtc));

      await expectLater(
        notifier.executeTransaction(),
        throwsA(isA<SideswapHttpStateNetworkError>()),
      );

      verifyNever(() => mockLiquid.signPsbt(any()));
      verifyNever(() => mockHttp.httpBodySign(any(), any(), any(), any()));
      expect(container.read(swapProvider).hasError, isTrue);
    });

    test('signs and submits a legitimate PSET', () async {
      // -sendAmount of the send asset, +recvAmount of the receive asset (the
      // over-sized UTXO surplus is returned to the wallet as change).
      when(() => mockLiquid.getDetailsPsbt(any()))
          .thenAnswer((_) async => replyWithWalletNet({
                recvAssetId: approvedRecvAmount,
                sendAssetId: -approvedSendAmount,
              }));

      final notifier = container.read(swapProvider.notifier);
      notifier
          .requestVerification(const SwapStartWebResponse(result: usdtToLbtc));

      await notifier.executeTransaction();

      final signedDetails = verify(() => mockLiquid.signPsbt(captureAny()))
          .captured
          .single as GdkSignPsbtDetails;
      expect(signedDetails.psbt, servicePset);

      final signSubmit = verify(() =>
              mockHttp.httpBodySign(captureAny(), any(), captureAny(), any()))
          .captured;
      expect(signSubmit[0], signedServicePset);
      expect(signSubmit[1], submitId);

      expect(container.read(swapProvider).hasError, isFalse);
    });

    test('rejects an order exceeding the user-entered amount before uploading',
        () async {
      // User approved sending less than the server's order now claims.
      container.dispose();
      container =
          makeContainer(approvedInput(deliverSats: approvedSendAmount - 1));

      final notifier = container.read(swapProvider.notifier);
      notifier
          .requestVerification(const SwapStartWebResponse(result: usdtToLbtc));

      await expectLater(
        notifier.executeTransaction(),
        throwsA(isA<SideswapHttpStateNetworkError>()),
      );

      // The order is rejected up front: nothing is uploaded, fetched or signed.
      verifyNever(() => mockHttp.httpStartWebParamsBody(any(), any(), any()));
      verifyNever(() => mockLiquid.getDetailsPsbt(any()));
      verifyNever(() => mockLiquid.signPsbt(any()));
      expect(container.read(swapProvider).hasError, isTrue);
    });
  });
}
