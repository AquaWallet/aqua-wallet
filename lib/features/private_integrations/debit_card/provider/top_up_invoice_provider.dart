import 'dart:async';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:http/http.dart' as http;

final _logger = CustomLogger(FeatureFlag.debitCard);

final topUpInvoiceProvider =
    AutoDisposeAsyncNotifierProvider<TopUpInvoiceProvider, TopUpInvoiceState>(
        TopUpInvoiceProvider.new);

class TopUpInvoiceProvider extends AutoDisposeAsyncNotifier<TopUpInvoiceState> {
  @override
  FutureOr<TopUpInvoiceState> build() {
    ref.listen(topUpInputStateProvider, (prev, next) {
      final prevAsset = prev?.valueOrNull?.asset;
      final nextAsset = next.valueOrNull?.asset;
      if (nextAsset != null && prevAsset != nextAsset) {
        state = AsyncValue.data(TopUpInvoiceState(
          arguments: SendAssetArguments.fromAsset(nextAsset),
        ));
      }
    });
    return TopUpInvoiceState(arguments: _getArgsFromInvoice(null));
  }

  Future<void> generateInvoice() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final input = await ref.read(topUpInputStateProvider.future);
      final cards = await ref.read(moonCardsProvider.future);
      final api = await ref.read(jan3ApiServiceProvider.future);
      final response = await api.generateInvoice(InvoiceRequest(
        cardId: cards.first.id,
        usdAmount: input.amountInUsd!,
        currency: input.currency,
        blockchain: input.blockchain,
      ));
      if (response.isSuccessful && response.body != null) {
        final invoice = response.body!;
        final arguments = _getArgsFromInvoice(invoice);
        // NOTE - Although we can simulate the invoice payment by calling an API
        // endpoint, to be able to test the flow completely, we need to make an
        // actual transaction through the send flow. To do that, we are making a
        // redeposit payment to our own wallet by replacing the invoice address
        // with our own address.
        //TODO - This is a temporary work for testing purpose until we have
        // backend team's go ahead to test the invoice payment production.
        final amountForBip21 =
            ref.watch(receiveAssetAmountForBip21Provider(arguments.asset));
        final amountAsDecimal =
            ref.watch(parsedAssetAmountAsDecimalProvider(amountForBip21));
        final address = await ref.read(receiveAssetAddressProvider((
          arguments.asset,
          amountAsDecimal,
        )).future);
        await ref.read(sendAssetInputStateAdapterProvider).fromTopUpInputState(
              arguments: arguments,
              invoice: invoice,
              address: address,
            );
        return TopUpInvoiceState(
          invoice: invoice,
          arguments: arguments,
        );
      }
      _logger.error('Failed to generate invoice', response.error);
      throw TopUpInvoiceGenerationException();
    });
  }

  //NOTE - ONLY FOR DEV USAGE
  Future<http.Response> simulatePayment() async {
    final invoiceId = state.valueOrNull?.invoice?.id;
    if (invoiceId == null) {
      throw Exception('Invoice ID is null');
    }
    final (token, _) =
        await ref.read(secureStorageProvider).get(Jan3AuthNotifier.tokenKey);
    if (token == null) {
      throw Exception('Token is null');
    }

    const baseUrl = 'https://stagingapi.paywithmoon.com/v1/api-gateway';
    final uri = Uri.parse(
      '$baseUrl/onchain/invoice/$invoiceId/simulate-payment',
    );
    final response = await http.post(
      uri,
      headers: {
        'accept': 'application/json',
        'x-api-key': '169f98a897139a68b795',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final input = await ref.read(topUpInputStateProvider.future);
      final cards = await ref.read(moonCardsProvider.future);
      final api = await ref.read(jan3ApiServiceProvider.future);
      final balanceResponse = await api.addCardBalance(
        cards.first.id,
        AmountRequest(usdAmount: input.amountInUsd!),
      );
      if (balanceResponse.isSuccessful && balanceResponse.body != null) {
        return response;
      }
      throw Exception('Failed to add balance to card');
    }
    throw Exception('Failed to simulate payment');
  }

  SendAssetArguments _getArgsFromInvoice(GenerateInvoiceResponse? invoice) {
    final availableAssets = [
      ...?ref.read(assetsProvider).valueOrNull?.where((e) => e.isInternal)
    ];
    final defaultArgs = SendAssetArguments.btc(
      availableAssets.firstWhere((e) => e.isBTC),
    );

    if (invoice == null) {
      return defaultArgs;
    }

    return switch (invoice.blockchain) {
      Blockchain.bitcoin => defaultArgs,
      Blockchain.liquid => invoice.currency == Currency.btc
          ? SendAssetArguments.lbtc(
              availableAssets.firstWhere((e) => e.isLBTC),
            )
          : SendAssetArguments.liquidUsdt(
              availableAssets.firstWhere((e) => e.isUsdtLiquid),
            ),
    };
  }
}
