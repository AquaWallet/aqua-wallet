import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/lightning/models/bolt11_ext.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'db_models.freezed.dart';
part 'db_models.g.dart';

enum BoltzVersion {
  v0, // Our manual implementation
  v2, // Boltz Dart V2
}

@freezed
@Collection(ignore: {'copyWith'})
class BoltzSwapDbModel with _$BoltzSwapDbModel {
  const BoltzSwapDbModel._();

  @JsonSerializable()
  const factory BoltzSwapDbModel({
    // Version of the Boltz implementation
    @Default(BoltzVersion.v2) @Enumerated(EnumType.name) BoltzVersion version,
    // Internal Isar table ID to used as primary key
    @Default(Isar.autoIncrement) @JsonKey(name: '_id') int id,
    // Boltz Swap ID
    @JsonKey(name: 'id', required: true, disallowNullValue: true)
    @Index()
    required String boltzId,
    @Enumerated(EnumType.name) required SwapType kind,
    @Enumerated(EnumType.name) required Chain network,
    String? fundingAddrs,
    required String hashlock,
    required String receiverPubkey,
    required String senderPubkey,
    @Index() required String invoice,
    required int outAmount,
    String? outAddress,
    required String blindingKey,
    String? electrumUrl,
    String? boltzUrl,
    DateTime? createdAt,
    required int locktime,
    String? referralId,
    @Enumerated(EnumType.name) BoltzSwapStatus? lastKnownStatus,
    String? onchainSubmarineTxId,
    String? claimTxId,
    String? refundTxId,
    // V0 fields
    String? redeemScript,
    required String scriptAddress,
  }) = _BoltzSwapDbModel;

  // Required for Freezed-Isar interoperability
  @override
  // ignore: recursive_getters
  Id get id => id;

  factory BoltzSwapDbModel.fromJson(Map<String, dynamic> json) =>
      _$BoltzSwapDbModelFromJson(json);

  factory BoltzSwapDbModel.fromV2SwapResponse(LbtcLnSwap response) =>
      BoltzSwapDbModel(
        boltzId: response.id,
        kind: response.kind,
        network: response.network,
        invoice: response.invoice,
        outAmount: response.outAmount,
        blindingKey: response.blindingKey,
        electrumUrl: response.electrumUrl,
        boltzUrl: response.boltzUrl,
        hashlock: response.swapScript.hashlock,
        receiverPubkey: response.swapScript.receiverPubkey,
        senderPubkey: response.swapScript.senderPubkey,
        fundingAddrs: response.swapScript.fundingAddrs,
        locktime: response.swapScript.locktime,
        referralId: response.referralId,
        scriptAddress: response.scriptAddress,
        createdAt: DateTime.now(),
      );

  @Deprecated('Only used for migration, use `fromV2SwapResponse` instead')
  factory BoltzSwapDbModel.fromLegacySwap({
    required BoltzSwapData data,
    String? electrumUrl,
    String? boltzUrl,
  }) {
    return BoltzSwapDbModel(
      version: BoltzVersion.v0,
      boltzId: data.response.id,
      kind: SwapType.submarine,
      network: Chain.liquid,
      redeemScript: data.response.redeemScript,
      invoice: data.request.invoice,
      outAmount: data.response.expectedAmount,
      scriptAddress: '',
      blindingKey: data.response.blindingKey,
      createdAt: data.created,
      electrumUrl: electrumUrl,
      boltzUrl: boltzUrl,
      // REVIEW: V2 Fields, does not explicitly exist in the legacy response but most are required for V2
      fundingAddrs: data.response.address,
      hashlock: '',
      receiverPubkey: '',
      senderPubkey: '',
      outAddress: '',
      locktime: data.response.timeoutBlockHeight,
      onchainSubmarineTxId: data.onchainTxHash,
      refundTxId: data.refundTx,
      lastKnownStatus: data.swapStatus,
    );
  }

  @Deprecated('Only used for migration, use `fromV2SwapResponse` instead')
  factory BoltzSwapDbModel.fromLegacyRevSwap({
    required BoltzReverseSwapData data,
    String? electrumUrl,
    String? boltzUrl,
  }) {
    return BoltzSwapDbModel(
      version: BoltzVersion.v0,
      boltzId: data.response.id,
      kind: SwapType.reverse,
      network: Chain.liquid,
      redeemScript: data.response.redeemScript,
      invoice: data.response.invoice,
      outAmount: data.request.invoiceAmount,
      scriptAddress: data.response.lockupAddress,
      blindingKey: data.response.blindingKey,
      createdAt: data.created,
      electrumUrl: electrumUrl,
      boltzUrl: boltzUrl,
      // REVIEW: V2 Fields, does not explicitly exist in the legacy response but most are required for V2
      hashlock: '',
      receiverPubkey: '',
      senderPubkey: '',
      outAddress: '',
      locktime: data.response.timeoutBlockHeight,
      claimTxId: data.claimTx,
      lastKnownStatus: data.swapStatus,
    );
  }
}

@freezed
class KeyPairStorageModel with _$KeyPairStorageModel {
  const factory KeyPairStorageModel({
    required String publicKey,
    required String secretKey,
  }) = _KeyPairStorageModel;

  factory KeyPairStorageModel.fromKeyPair(KeyPair keys) => KeyPairStorageModel(
        publicKey: keys.publicKey,
        secretKey: keys.secretKey,
      );

  factory KeyPairStorageModel.fromJson(Map<String, dynamic> json) =>
      _$KeyPairStorageModelFromJson(json);
}

@freezed
class PreImageStorageModel with _$PreImageStorageModel {
  const factory PreImageStorageModel({
    required String value,
    required String sha256,
    required String hash160,
  }) = _PreImageStorageModel;

  factory PreImageStorageModel.fromPreImage(PreImage preImage) =>
      PreImageStorageModel(
        value: preImage.value,
        sha256: preImage.sha256,
        hash160: preImage.hash160,
      );
  factory PreImageStorageModel.fromJson(Map<String, dynamic> json) =>
      _$PreImageStorageModelFromJson(json);
}

// For consistency, secure storage key generation is now done on the model
const _normalSwapPrivateKeyStoragePrefix = 'boltzNormalPrivateKey_';
const _normalSwapPreImageStoragePrefix = 'boltzNormalPreImage_';
const _reverseSwapPrivateKeyStoragePrefix = 'boltzReversePrivateKey_';
const _reverseSwapPreImageStoragePrefix = 'boltzReversePreImage_';

extension BoltzSwapDbModelX on BoltzSwapDbModel {
  String get privateKeyStorageKey => kind == SwapType.submarine
      ? '$_normalSwapPrivateKeyStoragePrefix$boltzId'
      : '$_reverseSwapPrivateKeyStoragePrefix$boltzId';

  String get preImageStorageKey => kind == SwapType.submarine
      ? '$_normalSwapPreImageStoragePrefix$boltzId'
      : '$_reverseSwapPreImageStoragePrefix$boltzId';

  bool get isV2 => version == BoltzVersion.v2;

  bool get isPendingClaim => lastKnownStatus?.needsClaim ?? true;

  bool get isPendingRefund => lastKnownStatus?.needsRefund ?? true;

  int? get amountFromInvoice =>
      Bolt11Ext.getAmountFromLightningInvoice(invoice);

  LbtcLnSwap toV2SwapResponse(
    KeyPairStorageModel keyPair,
    PreImageStorageModel preImage,
  ) {
    return LbtcLnSwap(
      id: boltzId,
      kind: kind,
      network: network,
      invoice: invoice,
      outAmount: outAmount,
      blindingKey: blindingKey,
      electrumUrl: electrumUrl!,
      boltzUrl: boltzUrl!,
      scriptAddress: scriptAddress,
      referralId: referralId,
      keys: KeyPair(
        secretKey: keyPair.secretKey,
        publicKey: keyPair.publicKey,
      ),
      keyIndex: 0,
      preimage: PreImage(
        value: preImage.value,
        sha256: preImage.sha256,
        hash160: preImage.hash160,
      ),
      swapScript: LBtcSwapScriptStr(
        swapType: kind,
        hashlock: hashlock,
        receiverPubkey: receiverPubkey,
        locktime: locktime,
        senderPubkey: senderPubkey,
        blindingKey: blindingKey,
        fundingAddrs: fundingAddrs,
      ),
    );
  }
}

extension BoltzSwapDbModelListX on List<BoltzSwapDbModel> {
  List<BoltzSwapDbModel> sortByCreated() => sorted((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
}

extension BoltzSwapFutureListX on Future<List<BoltzSwapDbModel>> {
  Future<List<BoltzSwapDbModel>> sortByCreated() async {
    final orders = await this;
    return orders.sortByCreated();
  }
}
