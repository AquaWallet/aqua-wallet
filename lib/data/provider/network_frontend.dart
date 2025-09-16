import 'dart:async';
import 'dart:convert';

import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/data/models/gdk_models.dart';
import 'package:coin_cz/features/send/providers/send_asset_used_utxo_provider.dart';
import 'package:coin_cz/features/settings/shared/providers/prefs_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/wallet/wallet.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/wallet.dart';
import 'package:async/async.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:rxdart/rxdart.dart';

class InitializeNetworkFrontendException implements Exception {}

@JsonEnum()
enum NetworkType {
  @JsonValue('bitcoin')
  bitcoin,
  @JsonValue('bitcoin-testnet')
  bitcoinTestnet,
  @JsonValue('liquid')
  liquid,
  @JsonValue('liquid-testnet')
  liquidTestnet,
}

extension NetworkTypeExt on NetworkType {
  String get displayName {
    switch (this) {
      case NetworkType.bitcoin:
        return 'Bitcoin';
      case NetworkType.bitcoinTestnet:
        return 'Bitcoin Testnet';
      case NetworkType.liquid:
        return 'Liquid';
      case NetworkType.liquidTestnet:
        return 'Liquid Testnet';
    }
  }
}

typedef OnEventCallback = Future<void> Function(dynamic)?;

abstract class NetworkFrontend {
  NetworkFrontend({
    required this.ref,
    required this.session,
  }) {
    addEventListener(listener: _onGdkEvent);
    Timer.periodic(const Duration(minutes: 1), (timer) {
      session.libGdk.freeOldAuthHandler();
    });
  }

  int defaultFees = 0;
  bool isConnected = false;
  String networkName = '';
  ProviderRef ref;
  GdkSettingsEvent settings = const GdkSettingsEvent();
  String walletHashId = '';
  String internalMnemonic = '';
  GdkNetwork? _network;
  String get policyAsset => _network?.policyAsset ?? '';
  List<OnEventCallback?> _eventListeners = [];
  int _listenersCount = 0;
  Map<String, GdkAssetInformation>? allRawAssets;
  List<GdkTransaction>? _allTransactions;
  Map<String, dynamic>? _allBalances;

  final transactionEventSubject = PublishSubject<GdkTransactionEvent?>();
  final BehaviorSubject<List<GdkTransaction>> _transactionsSubject =
      BehaviorSubject();
  late final Stream<List<GdkTransaction>> transactionsStream =
      _transactionsSubject;

  final gdkNetworkEventSubject = PublishSubject<GdkNetworkEventStateEnum?>();

  final blockHeightEventSubject = BehaviorSubject<int>.seeded(0);

  bool get isLogged => walletHashId.isNotEmpty;

  Future<void> _onGdkEvent(dynamic value) async {
    final valueType = value.runtimeType.toString();
    switch (valueType) {
      case '_\$_GdkNetworkEvent':
      case '_\$GdkNetworkEventImpl':
        final result = value as GdkNetworkEvent;
        if (result.nextState == GdkNetworkEventStateEnum.connected &&
            !isLogged &&
            internalMnemonic.isNotEmpty) {
          logger.debug('[$runtimeType] Relogin to $networkName');
          await loginUser(
              credentials: GdkLoginCredentials(mnemonic: internalMnemonic));
        }

        if (isLogged &&
            result.currentState == GdkNetworkEventStateEnum.connected) {
          // refresh balances
          await getBalance(requiresRefresh: true);
        }

        break;
      case '_\$_GdkBlockEvent':
        // refresh balances
        await getBalance(requiresRefresh: true);
        break;
      case '_\$_GdkSettingsEvent':
        // do nothing for now
        break;
      case '_\$_GdkTransactionEvent':
      case '_\$GdkTransactionEventImpl':
        // refresh balances & transactions
        await getBalance(requiresRefresh: true);
        await getTransactions(requiresRefresh: true);
        break;
      default:
        logger.debug(
            '[$runtimeType] $networkName unimplemented event: ${value.runtimeType.toString()}');
    }
  }

  void addEventListener({required OnEventCallback listener}) {
    if (_listenersCount == _eventListeners.length) {
      if (_listenersCount == 0) {
        _eventListeners = List<OnEventCallback?>.filled(1, null);
      } else {
        final List<OnEventCallback?> newListeners =
            List<OnEventCallback?>.filled(_eventListeners.length * 2, null);
        for (int i = 0; i < _listenersCount; i++) {
          newListeners[i] = _eventListeners[i];
        }
        _eventListeners = newListeners;
      }
    }
    _eventListeners[_listenersCount++] = listener;
  }

  void _removeAt(int index) {
    _listenersCount -= 1;
    if (_listenersCount * 2 <= _eventListeners.length) {
      final List<OnEventCallback?> newListeners =
          List<OnEventCallback?>.filled(_listenersCount, null);

      for (int i = 0; i < index; i++) {
        newListeners[i] = _eventListeners[i];
      }

      for (int i = index; i < _listenersCount; i++) {
        newListeners[i] = _eventListeners[i + 1];
      }

      _eventListeners = newListeners;
    } else {
      for (int i = index; i < _listenersCount; i++) {
        _eventListeners[i] = _eventListeners[i + 1];
      }

      _eventListeners[_listenersCount] = null;
    }
  }

  void removeEventListener(OnEventCallback listener) {
    for (int i = 0; i < _listenersCount; i++) {
      final OnEventCallback? listenerAtIndex = _eventListeners[i];
      if (listenerAtIndex == listener) {
        _removeAt(i);
        break;
      }
    }
  }

  Future<void> notifyEventListeners(dynamic value) async {
    final int end = _listenersCount;
    for (int i = 0; i < end; i++) {
      try {
        await _eventListeners[i]?.call(value);
      } catch (e) {
        logger.error(e);
        logger.error(StackTrace.current);
      }
    }
  }

  Future<void> onError(dynamic error) async {
    logger.error(error);
  }

  bool _isErrorResult(Result result) {
    if (result.isError) {
      final error = result.asError!.error;
      final stackTrace = result.asError!.stackTrace;
      logger.error(error);
      logger.error(stackTrace);

      return true;
    }

    if (result is Result<GdkAuthHandlerStatus>) {
      final error = result.asValue?.value.error;
      final value = result.asValue?.value;
      if (error != null && error.isNotEmpty) {
        try {
          switch (error) {
            case 'id_invalid_address':
              throw GdkNetworkInvalidAddress(error);
            case 'id_fee_rate_is_below_minimum':
              throw GdkNetworkFeeBelowMinimum(error);
            case 'id_invalid_amount':
              throw GdkNetworkInvalidAmount(error);
            case 'id_insufficient_funds':
              throw GdkNetworkInsufficientFunds(error);
            case 'Insufficient funds for fees':
              throw GdkNetworkInsufficientFundsForFee(error);
            case 'Fee change below the dust threshold':
              throw GdkNetworkChangeBelowDustThreshold(error);
            case 'invalid subaccount 1' || 'Unknown subaccount':
              return true;
            default:
              final errorMessage = '${value?.action}: $error';
              throw GdkNetworkUnhandledException(errorMessage);
          }
        } on GdkNetworkException catch (err, stackTrace) {
          logger.error(err.toString());
          logger.error('[$runtimeType] Gdk error: ${err.errorMessage()}');
          logger.error(stackTrace);
          rethrow;
        }
      }
    }

    return false;
  }

  Future<bool> connect({GdkConnectionParams? params}) async {
    networkName = params!.name!;

    logger.debug('[$runtimeType] Connecting to $networkName');
    final result = await session.connect(connectionParams: params);

    isConnected = result;

    return result;
  }

  Future<bool> reconnectHint({required GdkReconnectHint hint}) async {
    logger.debug('[$runtimeType] $networkName is being ${hint.name}ed');
    return await session.reconnectHint(
        reconnectParams: GdkReconnectParams(hint: hint));
  }

  Future<bool> disconnect() async {
    if (!isConnected) {
      return true;
    }

    logger.debug('[$runtimeType] Disconnecting $networkName');
    final result = await session.disconnect();

    if (result) {
      isConnected = false;
      walletHashId = '';
      allRawAssets = null;
      _allTransactions = null;
    }

    return result;
  }

  Future<String?> loginUser({required GdkLoginCredentials credentials}) async {
    logger.debug('[$runtimeType] Login to $networkName');
    internalMnemonic = credentials.mnemonic;
    final result = await session.loginUser(credentials: credentials);

    if (_isErrorResult(result)) {
      return null;
    }

    _network = await getNetwork();

    walletHashId = result.asValue?.value.result?.loginUser?.walletHashId ?? '';

    return result.asValue?.value.result?.loginUser?.walletHashId;
  }

  Future<GdkUnspentOutputsReply?> getUnspentOutputs(
      {bool filterCachedSpentOutputs = true}) async {
    logger.debug('[GDK] Fetching unspent outputs');
    final result = await session.getUnspentOutputs();
    if (_isErrorResult(result)) {
      logger.error('[GDK] Error fetching unspent outputs');
      return null;
    }
    final GdkUnspentOutputsReply? utxos =
        result.asValue?.value.result?.unspentOutputs;

    if (utxos == null || utxos.unsentOutputs == null) {
      logger.warning('[GDK] getUnspentOutputs: No UTXOs found');
      return null;
    }

    if (!filterCachedSpentOutputs) {
      logger.debug('[GDK] getUnspentOutputs: Returning unfiltered UTXOs');
      return utxos;
    }

    final spentUtxos = ref.read(recentlySpentUtxosProvider);
    if (spentUtxos == null || spentUtxos.isEmpty) {
      logger.debug(
          '[GDK] getUnspentOutputs: Used UTXOs not found, returning unfiltered UTXOs');
      return utxos;
    }

    logger.debug(
        '[GDK] getUnspentOutputs: Found used UTXOs: ${spentUtxos.length}, filtering');
    final filteredUtxos =
        WalletUtils.filterRecentlySpentUtxos(utxos.unsentOutputs!, spentUtxos);

    logger.debug(
        '[GDK] getUnspentOutputs: Returning filtered UTXOs - original: ${utxos.unsentOutputs!.length} - filtered: ${filteredUtxos.length}');
    return GdkUnspentOutputsReply(unsentOutputs: filteredUtxos);
  }

  Future<GdkUnspentOutputsReply?> getUnspentOutputsForPrivateKey(
      String privateKey,
      {String? outputType}) async {
    logger.debug('[GDK] Fetching unspent outputs for private key');
    final result = await session.getUnspentOutputsForPrivateKey(privateKey,
        outputType: outputType);

    if (_isErrorResult(result)) {
      logger.error('[GDK] Error fetching unspent outputs for private key');
      return null;
    }

    final GdkUnspentOutputsReply? utxos =
        result.asValue?.value.result?.unspentOutputs;

    if (utxos == null || utxos.unsentOutputs == null) {
      logger.warning('[GDK] getUnspentOutputsForPrivateKey: No UTXOs found');
      return null;
    }

    logger.debug('[GDK] getUnspentOutputsForPrivateKey: Returning UTXOs');
    return utxos;
  }

  Future<List<GdkTransaction>?> getTransactions(
      {bool requiresRefresh = false,
      int first = 0,
      GdkGetTransactionsDetails? details}) async {
    if (requiresRefresh ||
        _allTransactions == null ||
        _allTransactions!.isEmpty) {
      final transactions = await _getTransactions(details: details);
      _allTransactions = transactions;
    }

    if (_allTransactions != null) {
      final newTransactions = <GdkTransaction>[];
      newTransactions.addAll(_allTransactions!);
      _transactionsSubject.add(newTransactions);
    }

    return _allTransactions;
  }

  Future<List<GdkTransaction>?> _getTransactions(
      {int first = 0, GdkGetTransactionsDetails? details}) async {
    final result =
        await session.getTransactions(first: first, details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    final transactions = result.asValue?.value.result?.transactions;
    final transactionsWithSwap = _detectSwapTransaction(transactions);

    return transactionsWithSwap;
  }

  Future<GdkPinData?> encryptWithPin(
      {required GdkEncryptWithPinParams params}) async {
    final result = await session.encryptWithPin(params: params);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.pinData;
  }

  Future<Object?> decryptWithPin(
      {required GdkDecryptWithPinParams params}) async {
    final result = await session.decryptWithPin(params: params);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.pinData;
  }

  List<GdkTransaction>? _detectSwapTransaction(
      List<GdkTransaction>? transactions) {
    return transactions?.map((t) {
      final satoshi = t.satoshi;
      final policyAmount = satoshi?[policyAsset] ?? 0;
      final fee = t.fee ?? 0;
      if (satoshi?.length == 2 &&
          satoshi?[policyAsset] != null &&
          (policyAmount.abs() > fee)) {
        // satoshi is always positive in gdk, check inputs and outputs manually
        final amounts = <String, int>{};
        final inputs = t.inputs ?? [];
        final outputs = t.outputs ?? [];
        for (var inOut in inputs.followedBy(outputs)) {
          if (inOut.isRelevant == true &&
              inOut.assetId != null &&
              inOut.satoshi != 0 &&
              inOut.satoshi != null) {
            amounts[inOut.assetId!] = (amounts[inOut.assetId] ?? 0) +
                inOut.satoshi! * (inOut.isOutput == true ? 1 : -1);
          }
        }
        if (amounts.length == 2 &&
            amounts.entries.first.value > 0 != amounts.entries.last.value > 0) {
          final swapOutgoing = amounts.entries.firstWhere((e) => e.value < 0);
          final swapIncoming = amounts.entries.firstWhere((e) => e.value > 0);
          return t.copyWith(
              swapOutgoingAssetId: swapOutgoing.key,
              swapOutgoingSatoshi: swapOutgoing.value,
              swapIncomingAssetId: swapIncoming.key,
              swapIncomingSatoshi: swapIncoming.value,
              type: GdkTransactionTypeEnum.swap);
        }
      }

      return t;
    }).toList();
  }

  Future<Map<String, GdkAssetInformation>?> getAssets() async {
    final userAssetIds = ref.read(prefsProvider).userAssetIds;
    GdkGetAssetsParameters params =
        GdkGetAssetsParameters(assetsId: userAssetIds);

    final result = await session.getAssets(params: params);
    if (result.asValue != null && result.asValue?.value != null) {
      allRawAssets = result.asValue!.value;
      return allRawAssets;
    } else {
      logger.error(
          "[ASSETS] NetworkFrontend: Received null value from backend method");
      return allRawAssets;
    }
  }

  Future<Result<void>> refreshAssets({bool requiresRefresh = false}) async {
    if (requiresRefresh || allRawAssets == null || allRawAssets!.isEmpty) {
      GdkAssetsParameters params = const GdkAssetsParameters();
      await session.refreshAssets(params: params);
      return Result<void>.value(null);
    }
    return Result<void>.value(null);
  }

  Future<List<String>?> generateMnemonic12() async {
    final result = await session.generateMnemonic12();

    return result.asValue!.value;
  }

  Future<bool> validateMnemonic(List<String> mnemonic) async {
    final result = await session.validateMnemonic(mnemonic);

    return result;
  }

  Future<Map<String, dynamic>?> getBalance({
    bool requiresRefresh = false,
    GdkGetBalance details = const GdkGetBalance(),
  }) async {
    if (requiresRefresh || _allBalances == null || _allBalances!.isEmpty) {
      final balances = await _getBalance(details: details);
      _allBalances = balances;
    }

    final newBalances = <String, dynamic>{};
    newBalances.addAll(_allBalances ?? <String, dynamic>{});
    return newBalances;
  }

  Future<Map<String, dynamic>?> _getBalance({
    GdkGetBalance details = const GdkGetBalance(),
  }) async {
    final result = await session.getBalance(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    logger.debug(
        "[$runtimeType] raw balances: ${result.asValue?.value.result?.balance}");

    return result.asValue?.value.result?.balance;
  }

  Future<GdkNetwork?> getNetwork() async {
    final result = await session.getNetworks();

    final network = result.asValue?.value?.networks?[networkName];
    return network;
  }

  Subaccount? get currentSubaccount => session.currentSubaccount;

  //WARNING: Do not set currentSubaccount here directly, use setActiveSubaccount in subaccounts_provider.dart so both bitcoin and liquid subaccounts can be set at the same time.
  Future<void> setCurrentSubaccount(Subaccount subaccount) async {
    await session.setCurrentSubaccount(subaccount);
  }

  Future<GdkWallet?> getSubaccount(int subaccount) async {
    final result = await session.getSubaccount(subaccount: subaccount);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.getSubaccount;
  }

  Future<List<GdkSubaccount>?> getSubaccounts({
    GdkGetSubaccountsDetails details = const GdkGetSubaccountsDetails(),
  }) async {
    final result = await session.getSubaccounts(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.subaccounts;
  }

  Future<GdkAuthHandlerStatus?> createSubaccount({
    required GdkSubaccount details,
  }) async {
    final result = await session.createSubaccount(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue!.value;
  }

  Future<GdkAuthHandlerStatus?> updateSubaccount({
    required GdkSubaccountUpdate details,
  }) async {
    final result = await session.updateSubaccount(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue!.value;
  }

  //TODO: We need to update names of main native subaccounts to "Main Account", and legacy subaccounts to "Legacy"
  Future<GdkAuthHandlerStatus?> createSegwitSubaccount() async {
    GdkSubaccount subaccount = const GdkSubaccount(
        type: GdkSubaccountTypeEnum.type_p2wpkh, name: "Main Account");

    final result = await session.createSubaccount(details: subaccount);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue!.value;
  }

  Future<GdkReceiveAddressDetails?> getReceiveAddress({
    GdkReceiveAddressDetails? details,
  }) async {
    final result = await session.getReceiveAddress(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.getReceiveAddress;
  }

  // Second parameter is lastPointer
  Future<(List<GdkPreviousAddress>, int?)?> getPreviousAddresses({
    GdkPreviousAddressesDetails details = const GdkPreviousAddressesDetails(),
  }) async {
    final result = await session.getPreviousAddresses(details: details);

    final list = result.asValue?.value.result?.list;
    final lastPointer = result.asValue?.value.result?.lastPointer;
    if (_isErrorResult(result) || list == null) {
      return null;
    }

    return (list, lastPointer);
  }

  Future<List<GdkPreviousAddress>> getAllPreviousAddresses() async {
    final fullList = <GdkPreviousAddress>[];
    int? lastPointer;
    do {
      final result = await getPreviousAddresses(
          details: GdkPreviousAddressesDetails(lastPointer: lastPointer));
      if (result?.$1 != null) {
        fullList.addAll(result!.$1);
      }
      lastPointer = result?.$2;
    } while (lastPointer != null);
    return fullList;
  }

  List<GdkPreviousAddress> getUsedAddresses(
      List<GdkTransaction> txs, List<GdkPreviousAddress> addrs) {
    final usedOutputAddress = <String>{};
    for (final tx in txs) {
      for (final output in tx.outputs!) {
        if (output.address != null) {
          usedOutputAddress.add(output.address!);
        }
      }
    }
    return addrs.where((addr) =>
        // Check unblinded address (it must be set for liquid only) or regular address value for bitcoin.
        // Transactions outputs in liquid contain unblinded addresses only.
        usedOutputAddress.contains(addr.unblindedAddress ?? addr.address)).toList();
  }

  Future<GdkSettingsEvent> getSettings() async {
    final result = await session.getSettings();

    return result.asValue!.value!;
  }

  Future<int> getDefaultFees() async {
    final result = await session.getFeeEstimates();

    return result.asValue?.value?.fees?.last ?? await minFeeRate();
  }

  Future<int> getFastFees() async {
    final result = await session.getFeeEstimates();

    return result.asValue?.value?.fees?[1] ?? await minFeeRate();
  }

  Future<bool> isValidAddress(String address) async {
    final result = await session.isValidAddress(address: address);

    return result.asValue!.value;
  }

  Future<void> onFeeEstimates(GdkGetFeeEstimatesEvent value) async {
    defaultFees = value.fees?.last ?? await minFeeRate();

    await notifyEventListeners(value);
  }

  Future<void> onBlockHeight(GdkBlockEvent value) async {
    await notifyEventListeners(value);

    blockHeightEventSubject.add(value.blockHeight ?? 0);
  }

  Future<void> onSettings(GdkSettingsEvent value) async {
    settings = value;

    await notifyEventListeners(value);
  }

  Future<void> onTransaction(GdkTransactionEvent value) async {
    await notifyEventListeners(value);

    transactionEventSubject.add(value);
  }

  Future<void> onSession(GdkSessionEvent value) async {
    isConnected = value.connected ?? false;

    await notifyEventListeners(value);
  }

  Future<void> onNetwork(GdkNetworkEvent value) async {
    isConnected = value.currentState == GdkNetworkEventStateEnum.connected;

    if (!isConnected) {
      walletHashId = '';
    }

    gdkNetworkEventSubject.add(value.currentState);

    await notifyEventListeners(value);
  }

  Future<GdkNewTransactionReply?> createTransaction({
    required GdkNewTransaction transaction,
    bool rbfEnabled = true,
    bool isRbfTx = false,
    Map<String, List<GdkUnspentOutputs>>? utxos,
  }) async {
    if (utxos == null) {
      logger.debug('[GDK] No UTXOs provided, fetching from getUnspentOutputs');
      final utxoResult = await getUnspentOutputs();
      if (utxoResult != null) {
        utxos = utxoResult.unsentOutputs;
      } else {
        logger.error('[GDK] Failed to fetch UTXOs');
      }
    } else {
      logger.debug('[GDK] Using provided UTXOs');
    }

    final result = await session.createTransaction(
      transaction: transaction,
      rbfEnabled: rbfEnabled,
      isRbfTx: isRbfTx,
      utxos: utxos,
    );

    if (_isErrorResult(result)) {
      logger
          .error('[GDK] Error creating transaction: ${result.asError?.error}');
      return null;
    }

    logger.debug(result.asValue!.value);
    return result.asValue?.value.result?.createTransaction;
  }

  Future<GdkSettingsEvent?> changeSettings(GdkSettingsEvent settings) async {
    final result = await session.changeSettings(settings: settings);

    if (_isErrorResult(result)) {
      return null;
    }

    logger.debug(result.asValue!.value);

    return result.asValue?.value.result?.changeSettings;
  }

  Future<GdkNewTransactionReply?> blindTransaction(
    GdkNewTransactionReply transactionReply,
  ) async {
    final result =
        await session.blindTransaction(transactionReply: transactionReply);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.blindTransaction;
  }

  Future<GdkNewTransactionReply?> signTransaction(
    GdkNewTransactionReply transactionReply,
  ) async {
    final result =
        await session.signTransaction(transactionReply: transactionReply);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.signTx;
  }

  Future<GdkNewTransactionReply?> sendTransaction(
      GdkNewTransactionReply transactionReply) async {
    final result =
        await session.sendTransaction(transactionReply: transactionReply);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value.result?.sendRawTx;
  }

  Future<GdkNewTransactionReply?> signPsbt(GdkSignPsbtDetails details) async {
    final result = await session.signPsbt(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    logger.debug(result.asValue!.value);

    return result.asValue?.value.result?.signPsbt;
  }

  Future<GdkNewTransactionReply?> getDetailsPsbt(
      GdkPsbtGetDetails details) async {
    final result = await session.getDetailsPsbt(details: details);

    if (_isErrorResult(result)) {
      return null;
    }

    logger.debug(result.asValue!.value);

    return result.asValue?.value.result?.getDetailsPsbt;
  }

  Future<GdkAmountData?> convertAmount(GdkConvertData valueDetails) async {
    final result = await session.convertAmount(valueDetails: valueDetails);

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value;
  }

  Future<bool> registerNetwork(GdkRegisterNetworkData networkData) async {
    final result = await session.registerNetwork(networkData: networkData);

    if (_isErrorResult(result)) {
      return false;
    }

    return true;
  }

  Future<void> setTransactionMemo(String txhash, String memo) async {
    final result = await session.setTransactionMemo(txhash, memo);
    if (result.isError) {
      throw GdkNetworkUnhandledException(result.asError ?? Object());
    }
    return;
  }

  Future<int> minFeeRate();

  Future<GdkCurrencyData?> getAvailableCurrencies() async {
    final result = await session.getAvailableCurrencies();

    if (_isErrorResult(result)) {
      return null;
    }

    return result.asValue?.value;
  }

  final WalletService session;

  Future<bool> init() async {
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
              logger.debug("${session.networkName} fees event: $result");

              onFeeEstimates(result);
              break;
            case 'block':
              final result = GdkBlockEvent.fromJson(
                  jsonMap['block'] as Map<String, dynamic>);
              logger.debug("${session.networkName} block event: $result");

              onBlockHeight(result);
              break;
            case 'settings':
              final result = GdkSettingsEvent.fromJson(
                  jsonMap['settings'] as Map<String, dynamic>);
              logger.debug("${session.networkName} settings event: $result");

              onSettings(result);
              break;
            case 'transaction':
              final result = GdkTransactionEvent.fromJson(
                  jsonMap['transaction'] as Map<String, dynamic>);
              logger.debug("${session.networkName} transaction event: $result");

              onTransaction(result);
              break;
            case 'session':
              final result = GdkSessionEvent.fromJson(
                  jsonMap['session'] as Map<String, dynamic>);
              logger.debug("${session.networkName} session event: $result");
              onSession(result);
              break;
            case 'network':
              final result = GdkNetworkEvent.fromJson(
                  jsonMap['network'] as Map<String, dynamic>);
              logger.debug("${session.networkName} network event: $result");
              onNetwork(result);
              break;

            default:
              logger
                  .warning('${session.networkName} unhandled event: $jsonMap');
          }
        }
      } catch (err) {
        logger.error(err);
      }
    }
  }
}

class GdkNetworkException implements Exception, ExceptionLocalized {
  final Object error;

  GdkNetworkException(this.error);

  String errorMessage() {
    return '$error';
  }

  @override
  String toLocalizedString(BuildContext context) => errorMessage();
}

class GdkNetworkUnhandledException extends GdkNetworkException {
  GdkNetworkUnhandledException(super.error);
}

class GdkNetworkInvalidAddress extends GdkNetworkException {
  GdkNetworkInvalidAddress(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.invalidAddress;
  }
}

class GdkNetworkFeeBelowMinimum extends GdkNetworkException {
  GdkNetworkFeeBelowMinimum(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.gdkNetworkFeeBelowMinimum;
  }
}

class GdkNetworkInvalidAmount extends GdkNetworkException {
  GdkNetworkInvalidAmount(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.gdkNetworkInvalidAmount;
  }
}

class GdkNetworkInsufficientFunds extends GdkNetworkException {
  GdkNetworkInsufficientFunds(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.gdkNetworkInsufficientFundsForFee;
  }
}

class GdkNetworkInsufficientFundsForFee extends GdkNetworkException {
  GdkNetworkInsufficientFundsForFee(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.gdkNetworkInsufficientFundsForFee;
  }
}

class GdkNetworkChangeBelowDustThreshold extends GdkNetworkException {
  GdkNetworkChangeBelowDustThreshold(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.gdkNetworkChangeBelowDustThreshold;
  }
}

class GdkNonExistentAccount extends GdkNetworkException {
  GdkNonExistentAccount(super.error);

  @override
  String toLocalizedString(BuildContext context) {
    return context.loc.insufficientFunds;
  }
}
