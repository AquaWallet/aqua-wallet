import 'dart:async';
import 'dart:convert';

import 'package:aqua/logger.dart';
import 'package:aqua/data/backend/gdk_backend_event.dart';
import 'package:aqua/wallet.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:isolator/isolator.dart';
import 'package:async/async.dart';

class NetworkBackend extends Backend<GdkBackendEvent> {
  NetworkBackend(BackendArgument<void> argument, this.session)
      : super(argument) {
    _authHandlerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      session.libGdk.freeOldAuthHandler();
    });
  }

  // ignore: unused_field
  Timer? _authHandlerTimer;
  final WalletService session;

  Future<bool> _init() async {
    return session.init(callback: onNotificationEvent);
  }

  Future<void> onNotificationEvent(dynamic value) async {
    if (value is String) {
      try {
        final jsonMap = jsonDecode(value) as Map<String, dynamic>;

        if (jsonMap.containsKey('event')) {
          switch (jsonMap['event']) {
            case 'fees':
              final result = GdkGetFeeEstimatesEvent.fromJson(jsonMap);
              logger.d("${session.networkName} event: $result");

              send(GdkBackendEvent.onFeeEstimates, result);
              break;
            case 'block':
              final result = GdkBlockEvent.fromJson(
                  jsonMap['block'] as Map<String, dynamic>);
              logger.d("${session.networkName} event: $result");

              send(GdkBackendEvent.onBlockHeight, result);
              break;
            case 'settings':
              final result = GdkSettingsEvent.fromJson(
                  jsonMap['settings'] as Map<String, dynamic>);
              logger.d("${session.networkName} event: $result");

              send(GdkBackendEvent.onSettings, result);
              break;
            case 'transaction':
              final result = GdkTransactionEvent.fromJson(
                  jsonMap['transaction'] as Map<String, dynamic>);
              logger.d("${session.networkName} event: $result");

              send(GdkBackendEvent.onTransaction, result);
              break;
            case 'session':
              final result = GdkSessionEvent.fromJson(
                  jsonMap['session'] as Map<String, dynamic>);
              logger.d("${session.networkName} event: $result");
              send(GdkBackendEvent.onSession, result);
              break;
            case 'network':
              final result = GdkNetworkEvent.fromJson(
                  jsonMap['network'] as Map<String, dynamic>);
              logger.d("${session.networkName} event: $result");
              send(GdkBackendEvent.onNetwork, result);
              break;

            default:
              logger.w('${session.networkName} unhandled event: $jsonMap');
          }
        }
      } catch (err) {
        logger.e(err);
      }
    }
  }

  Future<bool> _connect(GdkConnectionParams params) async {
    return session.connect(connectionParams: params);
  }

  Future<bool> _disconnect() async {
    return session.disconnect();
  }

  Future<Result<GdkAuthHandlerStatus>> _loginUser(
      GdkLoginCredentials credentials) async {
    return session.loginUser(credentials: credentials);
  }

  Future<Result<GdkAuthHandlerStatus>> _getTransactions(int first) async {
    return session.getTransactions(first: first);
  }

  Future<Result<GdkAuthHandlerStatus>> _getUnspentOutputs() async {
    return session.getUnspentOutputs();
  }

  Future<Result<void>> _refreshAssets(GdkAssetsParameters params) async {
    return session.refreshAssets(params: params);
  }

  Future<Result<Map<String, GdkAssetInformation>?>> _getAssets(
      GdkGetAssetsParameters params) async {
    return session.getAssets(params: params);
  }

  Future<Result<List<String>?>> _generateMnemonic12() async {
    return session.generateMnemonic12();
  }

  Future<bool> _validateMnemonic(List<String> mnemonic) async {
    return session.validateMnemonic(mnemonic);
  }

  Future<Result<GdkAuthHandlerStatus>> _getBalance(
      GdkGetBalance details) async {
    return session.getBalance(details: details);
  }

  Future<Result<GdkNetworks?>> _getNetworks() async {
    return session.getNetworks();
  }

  Future<Result<GdkAuthHandlerStatus>> _getSubaccount(int subaccount) async {
    return session.getSubaccount(subaccount: subaccount);
  }

  Future<Result<GdkAuthHandlerStatus>> _createSubaccount(
      GdkSubaccount subaccount) async {
    return session.createSubaccount(details: subaccount);
  }

  Future<Result<GdkAuthHandlerStatus>> _getReceiveAddress(
      GdkReceiveAddressDetails details) async {
    return session.getReceiveAddress(details: details);
  }

  Future<Result<GdkAuthHandlerStatus>> _getPreviousAddresses(
      GdkPreviousAddressesDetails details) async {
    return session.getPreviousAddresses(details: details);
  }

  Future<Result<GdkGetFeeEstimatesEvent?>> _getFeeEstimates() async {
    return session.getFeeEstimates();
  }

  Future<Result<bool>> _isValidAddress(String address) async {
    return session.isValidAddress(address: address);
  }

  Future<Result<GdkAuthHandlerStatus>> _createTransaction(
      GdkNewTransaction transaction) async {
    return session.createTransaction(transaction: transaction);
  }

  Future<Result<GdkAuthHandlerStatus>> _signTransaction(
      GdkNewTransactionReply transactionReply) async {
    return session.signTransaction(transactionReply: transactionReply);
  }

  Future<Result<GdkAuthHandlerStatus>> _sendTransaction(
      GdkNewTransactionReply transactionReply) async {
    return session.sendTransaction(transactionReply: transactionReply);
  }

  Future<Result<GdkAuthHandlerStatus>> _createPset(
      GdkCreatePsetDetails details) async {
    return session.createPset(details: details);
  }

  Future<Result<GdkAuthHandlerStatus>> _signPset(
      GdkSignPsetDetails details) async {
    return session.signPset(details: details);
  }

  Future<Result<GdkAmountData?>> _convertAmount(
      GdkConvertData valueDetails) async {
    return session.convertAmount(valueDetails: valueDetails);
  }

  Future<Result<bool>> _registerNetwork(
      GdkRegisterNetworkData networkData) async {
    return session.registerNetwork(networkData: networkData);
  }

  Future<Result<void>> _setTransactionMemo((String, String) tuple) {
    return session.setTransactionMemo(tuple.$1, tuple.$2);
  }

  Future<Result<GdkCurrencyData?>> _getAvailableCurrencies() {
    return session.getAvailableCurrencies();
  }

  @override
  Map<GdkBackendEvent, Function> get operations {
    return {
      GdkBackendEvent.init: _init,
      GdkBackendEvent.connect: _connect,
      GdkBackendEvent.disconnect: _disconnect,
      GdkBackendEvent.loginUser: _loginUser,
      GdkBackendEvent.getTransactions: _getTransactions,
      GdkBackendEvent.getUnspentOutputs: _getUnspentOutputs,
      GdkBackendEvent.refreshAssets: _refreshAssets,
      GdkBackendEvent.getAssets: _getAssets,
      GdkBackendEvent.generateMnemonic12: _generateMnemonic12,
      GdkBackendEvent.validateMnemonic: _validateMnemonic,
      GdkBackendEvent.getBalance: _getBalance,
      GdkBackendEvent.getNetworks: _getNetworks,
      GdkBackendEvent.getSubaccount: _getSubaccount,
      GdkBackendEvent.createSubaccount: _createSubaccount,
      GdkBackendEvent.getReceiveAddress: _getReceiveAddress,
      GdkBackendEvent.getPreviousAddresses: _getPreviousAddresses,
      GdkBackendEvent.getFeeEstimates: _getFeeEstimates,
      GdkBackendEvent.isValidAddress: _isValidAddress,
      GdkBackendEvent.createTransaction: _createTransaction,
      GdkBackendEvent.signTransaction: _signTransaction,
      GdkBackendEvent.sendTransaction: _sendTransaction,
      GdkBackendEvent.createPset: _createPset,
      GdkBackendEvent.signPset: _signPset,
      GdkBackendEvent.convertAmount: _convertAmount,
      GdkBackendEvent.registerNetwork: _registerNetwork,
      GdkBackendEvent.setTransactionMemo: _setTransactionMemo,
      GdkBackendEvent.getAvailableCurrencies: _getAvailableCurrencies,
    };
  }
}
