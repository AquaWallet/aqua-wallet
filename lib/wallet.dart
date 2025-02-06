import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:isolate';

import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/wallet/models/subaccount.dart';
import 'package:aqua/gdk.dart';
import 'package:aqua/logger.dart';
import 'package:async/async.dart';

abstract class WalletService {
  // ignore: prefer_typing_uninitialized_variables
  var context;
  // ignore: prefer_typing_uninitialized_variables
  var session;

  final libGdk = LibGdk();

  late String networkName = '';

  Subaccount? _currentSubaccount;
  Subaccount? get currentSubaccount => _currentSubaccount;

  final receivePort = ReceivePort();
  StreamSubscription<dynamic>? receivePortSubscription;

  int getSubAccount() {
    if (_currentSubaccount != null) {
      return _currentSubaccount!.subaccount.pointer!;
    }

    return networkName == 'Liquid' ? 0 : 1; //TODO: Revise this fallback logic
  }

  Future<void> setCurrentSubaccount(Subaccount subaccount) async {
    _currentSubaccount = subaccount;
    //TODO: Persist value in local storage so will be active after app restart
  }

  Future<Result<GdkAuthHandlerStatus>> getSubaccounts({
    required GdkGetSubaccountsDetails details,
  }) async {
    final status = await libGdk.getSubaccounts(
      session: session!,
      details: details,
    );

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> _resolveAuthHandlerStatus(
    GdkAuthHandlerStatus status,
  ) async {
    switch (status.status) {
      case GdkAuthHandlerStatusEnum.done:
        libGdk.cleanAuthHandler(status.authHandlerId);
        if (status.error != null && status.error!.isNotEmpty) {
          if (status.message != null) {
            logger.warning('${status.error}: ${status.message}');
          }
        }
        break;
      case GdkAuthHandlerStatusEnum.error:
        libGdk.cleanAuthHandler(status.authHandlerId);
        break;
      case GdkAuthHandlerStatusEnum.requestCode:
        logger.warning('Not implemented');
        break;
      case GdkAuthHandlerStatusEnum.resolveCode:
        logger.warning('Not implemented');
        break;
      case GdkAuthHandlerStatusEnum.call:
        final gdkAuthHandlerStatus =
            await libGdk.authHandlerCall(status.authHandlerId);

        if (gdkAuthHandlerStatus.isError) {
          return Result.error(gdkAuthHandlerStatus.asError!.error,
              gdkAuthHandlerStatus.asError!.stackTrace);
        }

        return _resolveAuthHandlerStatus(
          gdkAuthHandlerStatus.asValue!.value,
        );
    }

    return Result.value(status);
  }

  Future<bool> init({required Future<void> Function(dynamic) callback}) async {
    if (receivePortSubscription != null) {
      await receivePortSubscription!.cancel();
    }

    receivePort.listen(callback);
    context = libGdk.initContext(receivePort.sendPort.nativePort);

    return true;
  }

  Future<bool> connect({
    required GdkConnectionParams connectionParams,
  }) async {
    final sessionResult = libGdk.createSession();
    if (isErrorResult(sessionResult)) {
      return false;
    }

    final result = await libGdk.connect(
      session: sessionResult.asValue!.value,
      connectionParams: connectionParams,
      context: context,
    );

    if (isErrorResult(result)) {
      libGdk.destroySession(session: sessionResult.asValue!.value);
      return false;
    }

    session = sessionResult.asValue!.value;

    return true;
  }

  Future<bool> reconnectHint({
    required GdkReconnectParams reconnectParams,
  }) async {
    final result = await libGdk.reconnectHint(
      session: session!,
      reconnectParams: reconnectParams,
      context: context,
    );

    if (isErrorResult(result)) {
      return false;
    }

    return true;
  }

  Future<bool> disconnect() async {
    libGdk.destroySession(session: session!);

    session = null;

    return true;
  }

  Future<Result<GdkAuthHandlerStatus>> loginUser({
    GdkHwDevice? hwDevice,
    required GdkLoginCredentials credentials,
  }) async {
    var status = await libGdk.loginUser(
      session: session!,
      hwDevice: hwDevice,
      credentials: credentials,
    );

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> encryptWithPin({
    required GdkEncryptWithPinParams params,
  }) async {
    final status =
        await libGdk.encryptWithPin(session: session!, params: params);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> decryptWithPin({
    required GdkDecryptWithPinParams params,
  }) async {
    final status =
        await libGdk.decryptWithPin(session: session!, params: params);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getTransactions(
      {int first = 0, GdkGetTransactionsDetails? details}) async {
    final status = await libGdk.getTransactions(
      session: session!,
      details: details ??
          GdkGetTransactionsDetails(first: first, subaccount: getSubAccount()),
    );

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getUnspentOutputs() async {
    final status = await libGdk.getUnspentOutputs(
      session: session!,
      details: GdkGetUnspentOutputs(subaccount: getSubAccount()),
    );

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<Map<String, GdkAssetInformation>?>> getAssets({
    GdkGetAssetsParameters params = const GdkGetAssetsParameters(),
  }) async {
    final result = await libGdk.getAssets(session: session!, params: params);
    if (isErrorResult(result) || result.asValue == null) {
      if (result.isError) {
        return Result.error(result.asError!.error, result.asError!.stackTrace);
      } else {
        return Result.error("Result is null");
      }
    }
    return Result.value(result.asValue!.value);
  }

  Future<Result<void>> refreshAssets({
    GdkAssetsParameters params = const GdkAssetsParameters(),
  }) async {
    await libGdk.refreshAssets(session: session!, params: params);
    return Result<void>.value(null);
  }

  Future<Result<List<String>?>> generateMnemonic12() async {
    final result = await libGdk.generateMnemonic12();
    if (isErrorResult(result)) {
      return Result.value(null);
    }

    final mnemonic = result.asValue?.value;
    if (mnemonic == null) {
      return Result.value(null);
    }

    return Result.value(mnemonic.split(' '));
  }

  Future<bool> validateMnemonic(List<String> mnemonic) async {
    final result = await libGdk.validateMnemonic(mnemonic);

    if (isErrorResult(result)) {
      return false;
    }

    return result.asValue!.value;
  }

  Future<Result<GdkAuthHandlerStatus>> getBalance({
    required GdkGetBalance details,
  }) async {
    GdkGetBalance detailsWithSubaccount =
        details.copyWith(subaccount: getSubAccount());
    final status = await libGdk.getBalance(
      session: session!,
      details: detailsWithSubaccount,
    );

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkNetworks?>> getNetworks() async {
    final result = await libGdk.getNetworks();
    if (isErrorResult(result)) {
      return Result.value(null);
    }

    final networks = result.asValue!.value;
    final gdkNetworks =
        GdkNetworks.fromJson(jsonDecode(networks) as Map<String, dynamic>);
    return Result.value(gdkNetworks);
  }

  Future<Result<GdkAuthHandlerStatus>> getSubaccount(
      {required int subaccount}) async {
    final status =
        await libGdk.getSubaccount(session: session!, subaccount: subaccount);

    if (isErrorResult(status)) {
      return status;
    }

    return await _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getReceiveAddress({
    GdkReceiveAddressDetails? details,
  }) async {
    GdkReceiveAddressDetails detailsWithSubaccount =
        details ?? GdkReceiveAddressDetails(subaccount: getSubAccount());

    final status = await libGdk.getReceiveAddress(
        session: session!, details: detailsWithSubaccount);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> createSubaccount({
    required GdkSubaccount details,
  }) async {
    final status =
        await libGdk.createSubaccount(session: session!, details: details);

    if (isErrorResult(status)) {
      return status;
    }

    return await _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> updateSubaccount({
    required GdkSubaccountUpdate details,
  }) async {
    final status = await libGdk.updateSubaccount(
      session: session!,
      details: details,
    );

    if (isErrorResult(status)) {
      return status;
    }

    return await _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getPreviousAddresses(
      {required GdkPreviousAddressesDetails details}) async {
    GdkPreviousAddressesDetails detailsWithSubaccount =
        details.copyWith(subaccount: getSubAccount());
    final status = await libGdk.getPreviousAddresses(
        session: session!, details: detailsWithSubaccount);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkGetFeeEstimatesEvent?>> getFeeEstimates() async {
    final result = await libGdk.getFeeEstimates(session: session!);

    if (isErrorResult(result)) {
      return Result.value(null);
    }

    return Result.value(
        GdkGetFeeEstimatesEvent.fromJson(result.asValue!.value));
  }

  Future<Result<GdkSettingsEvent?>> getSettings() async {
    final result = await libGdk.getSettings(session: session!);

    if (isErrorResult(result)) {
      return Result.value(null);
    }

    return Result.value(GdkSettingsEvent.fromJson(result.asValue!.value));
  }

  Future<Result<GdkAuthHandlerStatus>> changeSettings(
      {required GdkSettingsEvent settings}) async {
    final status =
        await libGdk.changeSettings(session: session!, settings: settings);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<bool>> isValidAddress({required String address}) async {
    final status = await libGdk.isValidAddress(
        session: session!, address: address, subaccount: getSubAccount());

    if (isErrorResult(status)) {
      return Result.value(false);
    }

    final result = await _resolveAuthHandlerStatus(status.asValue!.value);
    final error = result.asValue?.value.error;
    if (error != null && error.isNotEmpty) {
      if (error == 'id_invalid_address') {
        return Result.value(false);
      } else if (error == 'id_unknown') {
        return Result.value(true);
      } else {
        if (isErrorResult(result)) {
          return Result.value(false);
        }
      }
    }

    return Result.value(true);
  }

  Future<Result<GdkAuthHandlerStatus>> createTransaction({
    required GdkNewTransaction transaction,
    bool rbfEnabled = true,
    bool isRbfTx = false,
    Map<String, List<GdkUnspentOutputs>>? utxos,
  }) async {
    GdkNewTransaction detailsWithSubaccount =
        transaction.copyWith(subaccount: getSubAccount());

    final status = await libGdk.createTransaction(
      session: session!,
      transaction: detailsWithSubaccount,
      rbfEnabled: rbfEnabled,
      isRbfTx: isRbfTx,
      utxos: utxos,
    );

    if (isErrorResult(status)) {
      return status;
    }

    return await _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> blindTransaction({
    required GdkNewTransactionReply transactionReply,
  }) async {
    GdkNewTransactionReply detailsWithSubaccount =
        transactionReply.copyWith(subaccount: getSubAccount());
    final status = await libGdk.blindTransaction(
        session: session!, transactionReply: detailsWithSubaccount);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> signTransaction({
    required GdkNewTransactionReply transactionReply,
  }) async {
    GdkNewTransactionReply detailsWithSubaccount =
        transactionReply.copyWith(subaccount: getSubAccount());
    final status = await libGdk.signTransaction(
        session: session!, transactionReply: detailsWithSubaccount);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> sendTransaction({
    required GdkNewTransactionReply transactionReply,
  }) async {
    GdkNewTransactionReply detailsWithSubaccount =
        transactionReply.copyWith(subaccount: getSubAccount());
    final status = await libGdk.sendTransaction(
        session: session!, transactionReply: detailsWithSubaccount);

    if (isErrorResult(status)) {
      return status;
    }

    return _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> signPsbt({
    required GdkSignPsbtDetails details,
  }) async {
    final status = await libGdk.signPsbt(session: session!, details: details);

    if (isErrorResult(status)) {
      return status;
    }

    return await _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getDetailsPsbt({
    required GdkPsbtGetDetails details,
  }) async {
    final status =
        await libGdk.getDetailsPsbt(session: session!, details: details);

    if (isErrorResult(status)) {
      return status;
    }

    return await _resolveAuthHandlerStatus(status.asValue!.value);
  }

  Future<Result<GdkAmountData?>> convertAmount({
    required GdkConvertData valueDetails,
  }) async {
    final result = await libGdk.convertAmount(
        session: session!, valueDetails: valueDetails);

    if (isErrorResult(result)) {
      return Result.value(null);
    }

    return Result.value(GdkAmountData.fromJson(result.asValue!.value));
  }

  Future<Result<bool>> registerNetwork({
    required GdkRegisterNetworkData networkData,
  }) async {
    final result = await libGdk.registerNetwork(
        name: networkData.name!, networkDetails: networkData.networkDetails!);

    if (isErrorResult(result)) {
      return Result.value(false);
    }

    return Result.value(true);
  }

  Future<Result<void>> setTransactionMemo(String txhash, String memo) {
    return libGdk.setTransactionMemo(
        session: session!, txhash: txhash, memo: memo);
  }

  Future<Result<GdkCurrencyData?>> getAvailableCurrencies() async {
    final result = await libGdk.getAvailableCurrencies(session: session!);

    if (isErrorResult(result)) {
      return Result.value(null);
    }

    return Result.value(GdkCurrencyData.fromJson(result.asValue!.value));
  }
}

bool isErrorResult(Result result) {
  if (result.isError) {
    final error = result.asError!.error;
    final stackTrace = result.asError!.stackTrace;
    logger.error(error);
    logger.error(stackTrace);

    return true;
  }

  return false;
}
