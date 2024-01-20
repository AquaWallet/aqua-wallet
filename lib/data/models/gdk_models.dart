import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
part 'gdk_models.freezed.dart';
part 'gdk_models.g.dart';

enum GdkConfigLogLevelEnum {
  @JsonValue('debug')
  debug,
  @JsonValue('info')
  info,
  @JsonValue('warn')
  warn,
  @JsonValue('error')
  error,
  @JsonValue('none')
  none,
}

@freezed
class GdkConfig with _$GdkConfig {
  const GdkConfig._();
  const factory GdkConfig({
    @JsonKey(name: 'datadir') String? dataDir,
    @JsonKey(name: 'tordir') String? torDir,
    @JsonKey(name: 'registrydir') String? registryDir,
    @JsonKey(name: 'log_level', defaultValue: GdkConfigLogLevelEnum.info)
    GdkConfigLogLevelEnum? logLevel,
  }) = _GdkConfig;

  factory GdkConfig.fromJson(Map<String, dynamic> json) =>
      _$GdkConfigFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkConnectionParams with _$GdkConnectionParams {
  const GdkConnectionParams._();
  const factory GdkConnectionParams({
    String? name,
    String? proxy,
    @Default(false) @JsonKey(name: 'use_tor') bool? useTor,
    @Default('aqua') @JsonKey(name: 'user_agent') String? userAgent,
    @JsonKey(name: 'spv_enabled') bool? spvEnabled,
    @JsonKey(name: 'cert_expiry_threshold') int? certExpiryThreshold,
  }) = _GdkConnectionParams;

  factory GdkConnectionParams.fromJson(Map<String, dynamic> json) =>
      _$GdkConnectionParamsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkPinData with _$GdkPinData {
  const factory GdkPinData({
    @JsonKey(name: 'encrypted_data') String? encryptedData,
    @JsonKey(name: 'pin_identifier') String? pinIdentifier,
    String? salt,
  }) = _GdkPinData;

  factory GdkPinData.fromJson(Map<String, dynamic> json) =>
      _$GdkPinDataFromJson(json);
}

@freezed
class GdkLoginCredentials with _$GdkLoginCredentials {
  const GdkLoginCredentials._();
  const factory GdkLoginCredentials({
    required String mnemonic,
    String? username,
    @Default('') String password,
    @JsonKey(name: 'bip39_passphrase') String? bip39Passphrase,
    String? pin,
    @JsonKey(name: 'pin_data') GdkPinData? pinData,
  }) = _GdkLoginCredentials;

  factory GdkLoginCredentials.fromJson(Map<String, dynamic> json) =>
      _$GdkLoginCredentialsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkDevice with _$GdkDevice {
  const GdkDevice._();
  const factory GdkDevice({
    String? name,
    @JsonKey(name: 'supports_ae_protocol') int? supportsAeProtocol,
    @JsonKey(name: 'supports_arbitrary_scripts') bool? supportsArbitraryScripts,
    @JsonKey(name: 'supports_host_unblinding') bool? supportsHostUnblinding,
    @JsonKey(name: 'supports_liquid') int? supportsLiquid,
    @JsonKey(name: 'supports_low_r') bool? supportsLowR,
  }) = _GdkDevice;

  factory GdkDevice.fromJson(Map<String, dynamic> json) =>
      _$GdkDeviceFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkHwDevice with _$GdkHwDevice {
  const GdkHwDevice._();
  const factory GdkHwDevice({
    GdkDevice? device,
  }) = _GdkHwDevice;

  factory GdkHwDevice.fromJson(Map<String, dynamic> json) =>
      _$GdkHwDeviceFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

enum GdkSubaccountTypeEnum {
  @JsonValue('2of2')
  type_2of2,
  @JsonValue('2of3')
  type_2of3,
  @JsonValue('2of2_no_recovery')
  // ignore: constant_identifier_names
  type_2of2_no_recovery,
  @JsonValue('p2pkh')
  // ignore: constant_identifier_names
  type_p2pkh,
  @JsonValue('p2wpkh')
  // ignore: constant_identifier_names
  type_p2wpkh,
  @JsonValue('p2sh-p2wpkh')
  // ignore: constant_identifier_names
  type_p2sh_p2wpkh,
}

@freezed
class GdkSubaccount with _$GdkSubaccount {
  const GdkSubaccount._();
  const factory GdkSubaccount({
    @Default(false) bool? hidden,
    @Default('Managed Assets') String? name,
    int? pointer,
    @JsonKey(name: 'receiving_id') String? receivingId,
    @JsonKey(name: 'recovery_chain_code') String? recoveryChainCode,
    @JsonKey(name: 'recovery_pub_key') String? recoveryPubKey,
    @JsonKey(name: 'recovery_xpub') String? recoveryXpub,
    @JsonKey(name: 'required_ca') int? requiredCa,
    @Default(GdkSubaccountTypeEnum.type_p2sh_p2wpkh)
    GdkSubaccountTypeEnum? type,
    @JsonKey(name: 'bip44_discovered') bool? bip44Discovered,
  }) = _GdkSubaccount;

  factory GdkSubaccount.fromJson(Map<String, dynamic> json) =>
      _$GdkSubaccountFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

enum GdkAuthHandlerStatusEnum {
  @JsonValue('done')
  done,
  @JsonValue('error')
  error,
  @JsonValue('request_code')
  requestCode,
  @JsonValue('resolve_code')
  resolveCode,
  @JsonValue('call')
  call
}

@freezed
class GdkLoginUser with _$GdkLoginUser {
  const factory GdkLoginUser({
    @JsonKey(name: 'wallet_hash_id') String? walletHashId,
  }) = _GdkLoginUser;

  factory GdkLoginUser.fromJson(Map<String, dynamic> json) =>
      _$GdkLoginUserFromJson(json);
}

@freezed
class GdkGetBalance with _$GdkGetBalance {
  const GdkGetBalance._();
  const factory GdkGetBalance({
    @Default(1) int? subaccount,
    @Default(0) @JsonKey(name: 'num_confs') int? numConfs,
    @JsonKey(name: 'all_coins', defaultValue: true) bool? allCoins,
    @JsonKey(name: 'expired_at') int? expiredAt,
    @JsonKey(defaultValue: false) bool? confidential,
    @JsonKey(name: 'dust_limit') int? dustLimit,
  }) = _GdkGetBalance;

  factory GdkGetBalance.fromJson(Map<String, dynamic> json) =>
      _$GdkGetBalanceFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkAssetsParameters with _$GdkAssetsParameters {
  const GdkAssetsParameters._();
  const factory GdkAssetsParameters({
    @Default(true) bool? icons,
    @Default(true) bool? assets,
    @Default(true) bool? refresh,
  }) = _GdkAssetsParameters;

  factory GdkAssetsParameters.fromJson(Map<String, dynamic> json) =>
      _$GdkAssetsParametersFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkGetAssetsParameters with _$GdkGetAssetsParameters {
  const GdkGetAssetsParameters._();
  const factory GdkGetAssetsParameters({
    List<String>? assets_id,
  }) = _GdkGetAssetsParameters;

  factory GdkGetAssetsParameters.fromJson(Map<String, dynamic> json) =>
      _$GdkGetAssetsParametersFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

// internal Aqua helper type
@freezed
class GdkAuthHandlerStatusResult with _$GdkAuthHandlerStatusResult {
  const factory GdkAuthHandlerStatusResult({
    @JsonKey(name: 'login_user') GdkLoginUser? loginUser,
    List<GdkTransaction>? transactions,
    Map<String, dynamic>? balance,
    @JsonKey(name: 'get_subaccount') GdkWallet? getSubaccount,
    @JsonKey(name: 'get_receive_address')
    GdkReceiveAddressDetails? getReceiveAddress,
    @JsonKey(name: 'last_pointer') int? lastPointer,
    List<GdkPreviousAddress>? list,
    @JsonKey(name: 'create_transaction')
    GdkNewTransactionReply? createTransaction,
    @JsonKey(name: 'sign_tx') GdkNewTransactionReply? signTx,
    @JsonKey(name: 'send_raw_tx') GdkNewTransactionReply? sendRawTx,
    @JsonKey(name: 'create_pset') GdkCreatePsetDetailsReply? createPset,
    @JsonKey(name: 'sign_pset') GdkSignPsetDetailsReply? signPset,
    @JsonKey(name: 'sign_psbt') GdkSignPsbtResult? signPsbt,
    @JsonKey(name: 'unspent_outputs') GdkUnspentOutputsReply? unspentOutputs,
  }) = _GdkAuthHandlerStatusResult;

  factory GdkAuthHandlerStatusResult.fromJson(Map<String, dynamic> json) =>
      _$GdkAuthHandlerStatusResultFromJson(json);
}

@freezed
class GdkAuthHandlerStatus with _$GdkAuthHandlerStatus {
  const GdkAuthHandlerStatus._();
  const factory GdkAuthHandlerStatus({
    required GdkAuthHandlerStatusEnum status,
    GdkAuthHandlerStatusResult? result,
    List<String>? methods,
    String? error,
    String? action,
    @JsonKey(name: 'auth_data') Map<String, dynamic>? authData,
    @JsonKey(name: 'attempts_remaining') int? attemptsRemaining,
    String? device,
    String? message,
    String? authHandlerId,
    @JsonKey(name: 'required_data') Map<String, dynamic>? requiredData,
  }) = _GdkAuthHandlerStatus;

  factory GdkAuthHandlerStatus.fromJson(Map<String, dynamic> json) =>
      GdkAuthHandlerStatus.createFromJson(json);

  factory GdkAuthHandlerStatus.createFromJson(Map<String, dynamic> json) {
    if (json.containsKey('action') && json.containsKey('status')) {
      if (json['status'] == 'done') {
        if (json.containsKey('result') &&
            json['result'] is Map<String, dynamic> &&
            (json['result'] as Map<String, dynamic>).containsKey('error') &&
            (json['result']['error'] as String).isNotEmpty) {
          json['error'] = json['result']['error'];
          json['message'] = json['result']['message'];
        } else {
          switch (json['action']) {
            case 'login_user':
              json['result'] = <String, dynamic>{'login_user': json['result']};
              break;
            case 'get_balance':
              json['result'] = <String, dynamic>{'balance': json['result']};
              break;
            case 'get_subaccount':
              json['result'] = <String, dynamic>{
                'get_subaccount': json['result']
              };
              break;
            case 'get_receive_address':
              json['result'] = <String, dynamic>{
                'get_receive_address': json['result']
              };
              break;
            case 'create_transaction':
              json['result'] = <String, dynamic>{
                'create_transaction': json['result']
              };
              break;
            case 'sign_transaction':
              json['result'] = <String, dynamic>{'sign_tx': json['result']};
              break;
            case 'send_raw_tx':
              json['result'] = <String, dynamic>{'send_raw_tx': json['result']};
              break;
            case 'create_pset':
              json['result'] = <String, dynamic>{'create_pset': json['result']};
              break;
            case 'sign_pset':
              json['result'] = <String, dynamic>{'sign_pset': json['result']};
              break;
            case 'get_unspent_outputs':
              json['result'] = <String, dynamic>{
                'unspent_outputs': json['result']
              };
              break;
          }
        }
      }
    }
    return _$GdkAuthHandlerStatusFromJson(json);
  }
}

@freezed
class GdkGetTransactionsDetails with _$GdkGetTransactionsDetails {
  const GdkGetTransactionsDetails._();
  const factory GdkGetTransactionsDetails({
    @Default(1) int? subaccount,
    @Default(0) int? first,
    @Default(100) int? count,
  }) = _GdkGetTransactionsDetails;

  factory GdkGetTransactionsDetails.fromJson(Map<String, dynamic> json) =>
      _$GdkGetTransactionsDetailsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

// See GetTxInOut at gdk_rust/gdk_common/src/model.rs for reference
@freezed
class GdkTransactionInOut with _$GdkTransactionInOut {
  const factory GdkTransactionInOut({
    String? address,
    @JsonKey(name: 'address_type') String? addressType,
    @JsonKey(name: 'is_output') bool? isOutput,
    @JsonKey(name: 'is_relevant') bool? isRelevant,
    @JsonKey(name: 'is_spent') bool? isSpent,
    int? pointer,
    @JsonKey(name: 'pt_idx') int? ptIdx,
    int? satoshi,
    @JsonKey(name: 'script_type') int? scriptType,
    @Default(1) int? subaccount,
    int? subtype,
    @JsonKey(name: 'asset_id') String? assetId,
    @JsonKey(name: 'assetblinder') String? assetBlinder,
    @JsonKey(name: 'amountblinder') String? amountBlinder,
  }) = _GdkTransactionInOut;

  factory GdkTransactionInOut.fromJson(Map<String, dynamic> json) =>
      _$GdkTransactionInOutFromJson(json);
}

enum GdkTransactionTypeEnum {
  @JsonValue('incoming')
  incoming,
  @JsonValue('outgoing')
  outgoing,
  @JsonValue('redeposit')
  redeposit,
  @JsonValue('unknown')
  unknown,
  @JsonValue('mixed')
  mixed,
  @JsonValue('swap')
  swap,
}

// See TxListItem at gdk_rust/gdk_common/src/model.rs for reference
@freezed
class GdkTransaction with _$GdkTransaction {
  const GdkTransaction._();
  const factory GdkTransaction({
    List<String>? addressees,
    @JsonKey(name: 'block_height') int? blockHeight,
    @JsonKey(name: 'calculated_fee_rate') int? calculatedFeeRate,
    @JsonKey(name: 'can_cpfp') bool? canCpfp,
    @JsonKey(name: 'can_rbf') bool? canRbf,
    @JsonKey(name: 'created_at_ts') int? createdAtTs,
    int? fee,
    @JsonKey(name: 'fee_rate') int? feeRate,
    @JsonKey(name: 'has_payment_request') bool? hasPaymentRequest,
    List<GdkTransactionInOut>? inputs,
    bool? instant,
    String? memo,
    List<GdkTransactionInOut>? outputs,
    @JsonKey(name: 'rbf_optin') bool? rbfOptin,
    Map<String, int>? satoshi,
    @JsonKey(name: 'server_signed') bool? serverSigned,
    @JsonKey(name: 'spv_verified') String? spvVerified,
    String? transaction,
    @JsonKey(name: 'transaction_locktime') int? transactionLocktime,
    @JsonKey(name: 'transaction_outputs') List<String>? transactionOutputs,
    @JsonKey(name: 'transaction_size') int? transactionSize,
    @JsonKey(name: 'transaction_version') int? transactionVersion,
    @JsonKey(name: 'transaction_vsize') int? transactionVsize,
    @JsonKey(name: 'transaction_weight') int? transactionWeight,
    String? txhash,
    GdkTransactionTypeEnum? type,
    @JsonKey(name: 'user_signed') bool? userSigned,
    int? vsize,
    String? swapOutgoingAssetId,
    int? swapOutgoingSatoshi,
    String? swapIncomingAssetId,
    int? swapIncomingSatoshi,
  }) = _GdkTransaction;

  factory GdkTransaction.fromJson(Map<String, dynamic> json) =>
      GdkTransaction.createFromJson(json);

  factory GdkTransaction.createFromJson(Map<String, dynamic> json) {
    return _$GdkTransactionFromJson(json);
  }
}

@freezed
class GdkEntity with _$GdkEntity {
  const factory GdkEntity({
    String? domain,
  }) = _GdkEntity;

  factory GdkEntity.fromJson(Map<String, dynamic> json) =>
      _$GdkEntityFromJson(json);
}

@freezed
class GdkContract with _$GdkContract {
  const factory GdkContract({
    GdkEntity? entity,
    @JsonKey(name: 'issuer_pubkey') String? issuerPubkey,
    String? name,
    String? nonce,
    int? precision,
    String? ticker,
    int? version,
  }) = _GdkContract;

  factory GdkContract.fromJson(Map<String, dynamic> json) =>
      _$GdkContractFromJson(json);
}

@freezed
class GdkIssuance with _$GdkIssuance {
  const factory GdkIssuance({
    String? txid,
    int? vout,
    int? vin,
  }) = _GdkIssuance;

  factory GdkIssuance.fromJson(Map<String, dynamic> json) =>
      _$GdkIssuanceFromJson(json);
}

@freezed
class GdkAssetInformation with _$GdkAssetInformation {
  const factory GdkAssetInformation({
    @JsonKey(name: 'asset_id') String? assetId,
    GdkContract? contract,
    GdkEntity? entity,
    @JsonKey(name: 'issuance_prevout') GdkIssuance? issuancePrevout,
    @JsonKey(name: 'issuance_txin') GdkIssuance? issuanceTxin,
    @JsonKey(name: 'issuer_pubkey') String? issuerPubkey,
    String? name,
    int? precision,
    String? ticker,
    int? version,
    String? icon,
  }) = _GdkAssetInformation;

  factory GdkAssetInformation.fromJson(Map<String, dynamic> json) =>
      _$GdkAssetInformationFromJson(json);
}

@freezed
class GdkNetworks with _$GdkNetworks {
  const GdkNetworks._();
  const factory GdkNetworks({
    List<String>? allNetworks,
    Map<String, GdkNetwork>? networks,
  }) = _GdkNetworks;

  factory GdkNetworks.fromJson(Map<String, dynamic> json) =>
      GdkNetworks.createFromJson(json);

  factory GdkNetworks.createFromJson(Map<String, dynamic> json) {
    if (json.containsKey('all_networks')) {
      final allNetworks = json['all_networks'] as List;
      final networks = <String, dynamic>{};
      for (var n in allNetworks) {
        networks[n as String] = json[n] as Map<String, dynamic>;
      }
      json['networks'] = networks;
    }
    return _$GdkNetworksFromJson(json);
  }
}

enum ServerTypeEnum {
  @JsonValue('electrum')
  electrum,
  @JsonValue('green')
  green,
  @JsonValue('greenlight')
  greenlight,
}

@freezed
class GdkNetwork with _$GdkNetwork {
  const GdkNetwork._();
  const factory GdkNetwork({
    @JsonKey(name: 'address_explorer_url') String? addressExplorerUrl,
    @JsonKey(name: 'address_registry_onion_url') String? assetRegistryOnionUrl,
    @JsonKey(name: 'asset_registry_url') String? assetRegistryUrl,
    @JsonKey(name: 'bech32_prefix') String? bech32Prefix,
    @JsonKey(name: 'bip21_prefix') String? bip21Prefix,
    @JsonKey(name: 'blech32_prefix') String? blech32Prefix,
    @JsonKey(name: 'blinded_prefix') int? blindedPrefix,
    @JsonKey(name: 'csv_buckets') List<int>? csvBuckets,
    @JsonKey(name: 'ct_bits') int? ctBits,
    @JsonKey(name: 'ct_exponent') int? ctExponent,
    bool? development,
    @JsonKey(name: 'electrum_tls') bool? electrumTls,
    @JsonKey(name: 'electrum_url') String? electrumUrl,
    bool? liquid,
    bool? mainnet,
    String? name,
    String? network,
    @JsonKey(name: 'p2pkh_version') int? p2PkhVersion,
    @JsonKey(name: 'p2sh_version') int? p2ShVersion,
    @JsonKey(name: 'policy_asset') String? policyAsset,
    @JsonKey(name: 'server_type') ServerTypeEnum? serverType,
    @JsonKey(name: 'service_chain_code') String? serviceChainCode,
    @JsonKey(name: 'service_pubkey') String? servicePubkey,
    @JsonKey(name: 'spv_enabled') bool? spvEnabled,
    @JsonKey(name: 'spv_multi') bool? spvMulti,
    @JsonKey(name: 'spv_servers') List<dynamic>? spvServers,
    @JsonKey(name: 'tx_explorer_url') String? txExplorerUrl,
    @JsonKey(name: 'wamp_cert_pins') List<String>? wampCertPins,
    @JsonKey(name: 'wamp_cert_roots') List<String>? wampCertRoots,
    @JsonKey(name: 'wamp_onion_url') String? wampOnionUrl,
    @JsonKey(name: 'wamp_url') String? wampUrl,
  }) = _GdkNetwork;

  factory GdkNetwork.fromJson(Map<String, dynamic> json) =>
      _$GdkNetworkFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkWallet with _$GdkWallet {
  const factory GdkWallet({
    @JsonKey(name: 'has_transactions') bool? hasTransactions,
    bool? hidden,
    String? name,
    int? pointer,
    @JsonKey(name: 'receiving_id') String? receivingId,
    @JsonKey(name: 'required_ca') int? requiredCa,
    Map<String, int>? satoshi,
    String? type,
  }) = _GdkWallet;

  factory GdkWallet.fromJson(Map<String, dynamic> json) =>
      _$GdkWalletFromJson(json);
}

enum GdkAddressTypeEnum {
  @JsonValue('csv')
  csv,
  @JsonValue('p2sh')
  p2sh,
  @JsonValue('p2wsh')
  p2wsh,
  @JsonValue('p2pkh')
  p2pkh,
  @JsonValue('p2sh-p2wpkh')
  // ignore: constant_identifier_names
  p2sh_p2wpkh,
  @JsonValue('p2wpkh')
  p2wpkh
}

@freezed
class GdkReceiveAddressDetails with _$GdkReceiveAddressDetails {
  const GdkReceiveAddressDetails._();
  const factory GdkReceiveAddressDetails({
    String? address,
    @JsonKey(name: 'address_type', defaultValue: GdkAddressTypeEnum.csv)
    GdkAddressTypeEnum? addressType,
    int? branch,
    int? pointer,
    String? script,
    @JsonKey(name: 'script_type') int? scriptType,
    @Default(1) int? subaccount,
    int? subtype,
    @JsonKey(name: 'user_path') List<int>? userPath,
  }) = _GdkReceiveAddressDetails;

  factory GdkReceiveAddressDetails.fromJson(Map<String, dynamic> json) =>
      _$GdkReceiveAddressDetailsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkPreviousAddressesDetails with _$GdkPreviousAddressesDetails {
  const GdkPreviousAddressesDetails._();
  const factory GdkPreviousAddressesDetails({
    @Default(0) int subaccount,
    @JsonKey(name: 'last_pointer') int? lastPointer,
    @JsonKey(name: 'is_internal') bool? isInternal,
  }) = _GdkPreviousAddressesDetails;

  factory GdkPreviousAddressesDetails.fromJson(Map<String, dynamic> json) =>
      _$GdkPreviousAddressesDetailsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkPreviousAddress with _$GdkPreviousAddress {
  const GdkPreviousAddress._();
  const factory GdkPreviousAddress({
    @JsonKey(name: 'address') String? address,
    @JsonKey(name: 'address_type') String? addressType,
    @JsonKey(name: 'subaccount') @Default(1) int? subaccount,
    @JsonKey(name: 'is_internal') bool? isInternal,
    @JsonKey(name: 'pointer') int? pointer,
    @JsonKey(name: 'script_pubkey') String? scriptPubkey,
    @JsonKey(name: 'user_path') List<int>? userPath,
    @JsonKey(name: 'tx_count') int? txCount,
    // For liquid only
    @JsonKey(name: 'is_blinded') bool? isBlinded,
    @JsonKey(name: 'unblinded_address') String? unblindedAddress,
    @JsonKey(name: 'blinding_script') String? blindingScript,
    @JsonKey(name: 'blinding_key') String? blindingKey,
  }) = _GdkPreviousAddress;

  factory GdkPreviousAddress.fromJson(Map<String, dynamic> json) =>
      _$GdkPreviousAddressFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkCreatePsetDetails with _$GdkCreatePsetDetails {
  const GdkCreatePsetDetails._();
  const factory GdkCreatePsetDetails({
    List<GdkAddressee>? addressees,
    @Default(1) int? subaccount,
    @JsonKey(name: 'send_asset') String? sendAsset,
    @JsonKey(name: 'send_amount') int? sendAmount,
    @JsonKey(name: 'recv_asset') String? recvAsset,
    @JsonKey(name: 'recv_amount') int? recvAmount,
  }) = _GdkCreatePsetDetails;

  factory GdkCreatePsetDetails.fromJson(Map<String, dynamic> json) =>
      _$GdkCreatePsetDetailsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkCreatePsetInputs with _$GdkCreatePsetInputs {
  const factory GdkCreatePsetInputs({
    String? asset,
    @JsonKey(name: 'asset_bf') String? assetBf,
    String? txid,
    int? value,
    @JsonKey(name: 'value_bf') String? valueBf,
    int? vout,
  }) = _GdkCreatePsetInputs;

  factory GdkCreatePsetInputs.fromJson(Map<String, dynamic> json) =>
      _$GdkCreatePsetInputsFromJson(json);
}

@freezed
class GdkCreatePsetDetailsReply with _$GdkCreatePsetDetailsReply {
  const GdkCreatePsetDetailsReply._();
  const factory GdkCreatePsetDetailsReply({
    @JsonKey(name: 'change_addr') String? changeAddr,
    List<GdkCreatePsetInputs>? inputs,
    @JsonKey(name: 'recv_addr') String? recvAddr,
  }) = _GdkCreatePsetDetailsReply;

  factory GdkCreatePsetDetailsReply.fromJson(Map<String, dynamic> json) =>
      _$GdkCreatePsetDetailsReplyFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkSignPsetDetails with _$GdkSignPsetDetails {
  const GdkSignPsetDetails._();
  const factory GdkSignPsetDetails({
    List<GdkAddressee>? addressees,
    @Default(1) int? subaccount,
    @JsonKey(name: 'pset') String? pset,
    @JsonKey(name: 'send_asset') String? sendAsset,
    @JsonKey(name: 'send_amount') int? sendAmount,
    @JsonKey(name: 'recv_asset') String? recvAsset,
    @JsonKey(name: 'recv_amount') int? recvAmount,
  }) = _GdkSignPsetDetails;

  factory GdkSignPsetDetails.fromJson(Map<String, dynamic> json) =>
      _$GdkSignPsetDetailsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkSignPsetDetailsReply with _$GdkSignPsetDetailsReply {
  const GdkSignPsetDetailsReply._();
  const factory GdkSignPsetDetailsReply({
    List<GdkAddressee>? addressees,
    @JsonKey(name: 'pset') String? pset,
  }) = _GdkSignPsetDetailsReply;

  factory GdkSignPsetDetailsReply.fromJson(Map<String, dynamic> json) =>
      _$GdkSignPsetDetailsReplyFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkSignPsbtDetails with _$GdkSignPsbtDetails {
  const GdkSignPsbtDetails._();
  const factory GdkSignPsbtDetails({
    @JsonKey(name: 'psbt') required String psbt,
    @JsonKey(name: 'utxos') required List<Map<String, dynamic>> utxos,
    @JsonKey(name: 'blinding_nonces') List<String>? blindingNonces,
  }) = _GdkSignPsbtDetails;

  factory GdkSignPsbtDetails.fromJson(Map<String, dynamic> json) =>
      _$GdkSignPsbtDetailsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkSignPsbtResult with _$GdkSignPsbtResult {
  const GdkSignPsbtResult._();
  const factory GdkSignPsbtResult({
    @JsonKey(name: 'psbt') required String psbt,
    @JsonKey(name: 'utxos') required List<Map<String, dynamic>> utxos,
  }) = _GdkSignPsbtResult;

  factory GdkSignPsbtResult.fromJson(Map<String, dynamic> json) =>
      _$GdkSignPsbtResultFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkGetFeeEstimatesEvent with _$GdkGetFeeEstimatesEvent {
  const factory GdkGetFeeEstimatesEvent({
    List<int>? fees,
  }) = _GdkGetFeeEstimatesEvent;

  factory GdkGetFeeEstimatesEvent.fromJson(Map<String, dynamic> json) =>
      _$GdkGetFeeEstimatesEventFromJson(json);
}

@freezed
class GdkBlockEvent with _$GdkBlockEvent {
  const factory GdkBlockEvent({
    @JsonKey(name: 'block_hash') String? blockHash,
    @JsonKey(name: 'block_height') int? blockHeight,
    @JsonKey(name: 'initial_timestamp') int? initialTimestamp,
    @JsonKey(name: 'previous_hash') String? previousHash,
  }) = _GdkBlockEvent;

  factory GdkBlockEvent.fromJson(Map<String, dynamic> json) =>
      _$GdkBlockEventFromJson(json);
}

@freezed
class GdkSettingsEventNotifications with _$GdkSettingsEventNotifications {
  const factory GdkSettingsEventNotifications({
    @JsonValue('email_incoming') bool? emailIncoming,
    @JsonValue('email_outgoing') bool? emailOutgoing,
  }) = _GdkSettingsEventNotifications;

  factory GdkSettingsEventNotifications.fromJson(Map<String, dynamic> json) =>
      _$GdkSettingsEventNotificationsFromJson(json);
}

@freezed
class GdkSettingsEvent with _$GdkSettingsEvent {
  const factory GdkSettingsEvent({
    int? altimeout,
    int? csvtime,
    int? nlocktime,
    GdkSettingsEventNotifications? notifications,
    String? pgp,
    GdkPricing? pricing,
    @JsonKey(name: 'required_num_blocks') int? requiredNumBlocks,
    bool? sound,
    String? unit,
  }) = _GdkSettingsEvent;

  factory GdkSettingsEvent.fromJson(Map<String, dynamic> json) =>
      _$GdkSettingsEventFromJson(json);
}

enum GdkTransactionEventEnum {
  @JsonValue('incoming')
  incoming,
  @JsonValue('outgoing')
  outgoing,
  @JsonValue('redeposit')
  redeposit
}

@freezed
class GdkTransactionEvent with _$GdkTransactionEvent {
  const factory GdkTransactionEvent({
    int? satoshi,
    List<int>? subaccounts,
    String? txhash,
    GdkTransactionEventEnum? type,
  }) = _GdkTransactionEvent;

  factory GdkTransactionEvent.fromJson(Map<String, dynamic> json) =>
      _$GdkTransactionEventFromJson(json);
}

@freezed
class GdkPricing with _$GdkPricing {
  const factory GdkPricing({
    String? currency,
    String? exchange,
  }) = _GdkPricing;

  factory GdkPricing.fromJson(Map<String, dynamic> json) =>
      _$GdkPricingFromJson(json);
}

@freezed
class GdkAddressee with _$GdkAddressee {
  const factory GdkAddressee({
    String? address,
    int? satoshi,
    @JsonKey(name: 'asset_id') String? assetId,
  }) = _GdkAddressee;

  factory GdkAddressee.fromJson(Map<String, dynamic> json) =>
      _$GdkAddresseeFromJson(json);
}

enum GdkUtxoStrategyEnum {
  @JsonValue('manual')
  manualStrategy,
  @JsonValue('default')
  defaultStrategy,
}

@freezed
class GdkNewTransaction with _$GdkNewTransaction {
  const GdkNewTransaction._();
  const factory GdkNewTransaction({
    List<GdkAddressee>? addressees,
    @Default(1) int? subaccount,
    @Default(1000) @JsonKey(name: 'fee_rate') int? feeRate,
    @Default(false) @JsonKey(name: 'send_all') bool? sendAll,
    @Default(GdkUtxoStrategyEnum.defaultStrategy)
    @JsonKey(name: 'utxo_strategy')
    GdkUtxoStrategyEnum? utxoStrategy,
    @JsonKey(name: 'used_utxos') String? usedUtxos,
    String? memo,
    Map<String, List<GdkUnspentOutputs>>? utxos,
  }) = _GdkNewTransaction;

  factory GdkNewTransaction.fromJson(Map<String, dynamic> json) =>
      _$GdkNewTransactionFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkNewTransactionReply with _$GdkNewTransactionReply {
  const GdkNewTransactionReply._();
  const factory GdkNewTransactionReply({
    List<GdkAddressee>? addressees,
    @JsonKey(name: 'addressees_have_assets') bool? addresseesHaveAssets,
    @JsonKey(name: 'addressees_read_only') bool? addresseesReadOnly,
    @JsonKey(name: 'changes_used') int? changesUsed,
    @JsonKey(name: 'confidential_utxos_only') bool? confidentialUtxosOnly,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    String? error,
    int? fee,
    @JsonKey(name: 'fee_rate') int? feeRate,
    @JsonKey(name: 'is_sweep') bool? isSweep,
    String? network,
    @JsonKey(name: 'num_confs') int? numConfs,
    @Default(true) @JsonKey(name: 'rbf_optin') bool? rbfOptin,
    Map<String, dynamic>? satoshi,
    @JsonKey(name: 'send_all') bool? sendAll,
    @JsonKey(name: 'spv_verified') String? spvVerified,
    @Default(1) int? subaccount,
    int? timestamp,
    String? transaction,
    @JsonKey(name: 'transaction_size') int? transactionSize,
    @JsonKey(name: 'transaction_vsize') int? transactionVsize,
    @JsonKey(name: 'transaction_weight') int? transactionWeight,
    @JsonKey(name: 'transaction_version') int? transactionVersion,
    @JsonKey(name: 'transaction_locktime') int? transactionLocktime,
    @JsonKey(name: 'transaction_outputs') dynamic transactionOutputs,
    @JsonKey(name: 'used_utxos') dynamic usedUtxos,
    String? txhash,
    GdkTransactionTypeEnum? type,
    @JsonKey(name: 'user_signed') bool? userSigned,
    @JsonKey(name: 'utxo_strategy') String? utxoStrategy,
    String? memo,
    Map<String, dynamic>? utxos,
  }) = _GdkNewTransactionReply;

  factory GdkNewTransactionReply.fromJson(Map<String, dynamic> json) =>
      _$GdkNewTransactionReplyFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkRegisterNetworkData with _$GdkRegisterNetworkData {
  const factory GdkRegisterNetworkData({
    String? name,
    GdkNetwork? networkDetails,
  }) = _GdkRegisterNetworkData;

  factory GdkRegisterNetworkData.fromJson(Map<String, dynamic> json) =>
      _$GdkRegisterNetworkDataFromJson(json);
}

@freezed
class GdkSessionEvent with _$GdkSessionEvent {
  const factory GdkSessionEvent({
    bool? connected,
  }) = _GdkSessionEvent;

  factory GdkSessionEvent.fromJson(Map<String, dynamic> json) =>
      _$GdkSessionEventFromJson(json);
}

enum GdkNetworkEventStateEnum {
  @JsonValue('connected')
  connected,
  @JsonValue('disconnected')
  disconnected,
}

// 0.55
// {"event":"network","network":{"current_state":"connected","next_state":"connected","wait_ms":0}}
@freezed
class GdkNetworkEvent with _$GdkNetworkEvent {
  const factory GdkNetworkEvent({
    @JsonKey(name: 'wait_ms') int? waitMs,
    @JsonKey(name: 'current_state') GdkNetworkEventStateEnum? currentState,
    @JsonKey(name: 'next_state') GdkNetworkEventStateEnum? nextState,
  }) = _GdkNetworkEvent;

  factory GdkNetworkEvent.fromJson(Map<String, dynamic> json) =>
      _$GdkNetworkEventFromJson(json);
}

@freezed
class GdkConvertData with _$GdkConvertData {
  const GdkConvertData._();
  const factory GdkConvertData({
    @Default(0) int? satoshi,
    String? bits,
    @JsonKey(name: 'fiat_currenct') String? fiatCurrency,
    @JsonKey(name: 'fiat_rate') String? fiatRate,
  }) = _GdkConvertData;

  factory GdkConvertData.fromJson(Map<String, dynamic> json) =>
      _$GdkConvertDataFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkAmountData with _$GdkAmountData {
  const factory GdkAmountData({
    String? bits,
    String? btc,
    String? fiat,
    @JsonKey(name: 'fiat_currency') String? fiatCurrency,
    @JsonKey(name: 'fiat_rate') String? fiatRate,
    String? mbtc,
    int? satoshi,
    String? sats,
    @Default(1) int? subaccount,
    String? ubtc,
    @JsonKey(name: 'is_current') bool? isCurrent,
  }) = _GdkAmountData;

  factory GdkAmountData.fromJson(Map<String, dynamic> json) =>
      _$GdkAmountDataFromJson(json);
}

@freezed
class GdkGetUnspentOutputs with _$GdkGetUnspentOutputs {
  const GdkGetUnspentOutputs._();
  const factory GdkGetUnspentOutputs({
    @Default(1) int? subaccount,
    @JsonKey(name: 'num_confs') @Default(0) int? numConfs,
    @JsonKey(name: 'all_coins') @Default(false) bool? allCoins,
    @JsonKey(name: 'expired_at') int? expiredAt,
    @Default(false) bool? confidential,
    @JsonKey(name: 'dust_limit') int? dustLimit,
  }) = _GdkGetUnspentOutputs;

  factory GdkGetUnspentOutputs.fromJson(Map<String, dynamic> json) =>
      _$GdkGetUnspentOutputsFromJson(json);

  String toJsonString() {
    final json = toJson();
    return jsonEncode(json);
  }
}

@freezed
class GdkUnspentOutputsReply with _$GdkUnspentOutputsReply {
  const factory GdkUnspentOutputsReply({
    @JsonKey(name: 'unspent_outputs')
    Map<String, List<GdkUnspentOutputs>>? unsentOutputs,
  }) = _GdkUnspentOutputsReply;

  factory GdkUnspentOutputsReply.fromJson(Map<String, dynamic> json) =>
      _$GdkUnspentOutputsReplyFromJson(json);
}

// See UnspentOutput at gdk_rust/gdk_common/src/model.rs for reference
@freezed
class GdkUnspentOutputs with _$GdkUnspentOutputs {
  const factory GdkUnspentOutputs({
    @JsonKey(name: 'address_type') String? addressType,
    @JsonKey(name: 'block_height') int? blockHeight,
    @JsonKey(name: 'is_internal') bool? isInternal,
    int? pointer,
    @JsonKey(name: 'pt_idx') int? ptIdx,
    int? satoshi,
    @Default(1) int? subaccount,
    String? txhash,
    @JsonKey(name: 'prevout_script') String? prevoutScript,
    @JsonKey(name: 'user_path') List<int>? userPath,
    @JsonKey(name: 'public_key') String? publicKey,
    @JsonKey(name: 'expiry_height') int? expiryHeight,
    @JsonKey(name: 'script_type') int? scriptType,
    @JsonKey(name: 'user_status') int? userStatus,
    int? subtype,
    // Liquid specific
    bool? confidential,
    @JsonKey(name: 'asset_id') String? assetId,
    @JsonKey(name: 'assetblinder') String? assetBlinder,
    @JsonKey(name: 'amountblinder') String? amountBlinder,
    @JsonKey(name: 'asset_tag') String? assetTag,
    String? commitment,
    @JsonKey(name: 'nonce_commitment') String? nonceCommitment,
  }) = _GdkUnspentOutputs;

  factory GdkUnspentOutputs.fromJson(Map<String, dynamic> json) =>
      _$GdkUnspentOutputsFromJson(json);
}

@freezed
class GdkCurrencyData with _$GdkCurrencyData {
  factory GdkCurrencyData({
    List<String>? all,
    @JsonKey(name: 'per_exchange') Map<String, List<String>>? perExchange,
  }) = _GdkCurrencyData;

  factory GdkCurrencyData.fromJson(Map<String, dynamic> json) =>
      _$GdkCurrencyDataFromJson(json);
}
