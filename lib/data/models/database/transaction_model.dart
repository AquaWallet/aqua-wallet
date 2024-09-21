import 'package:aqua/features/boltz/boltz.dart' hide SwapType;
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:boltz_dart/boltz_dart.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

enum TransactionDbModelType {
  @JsonValue('sideswapSwap')
  sideswapSwap,
  @JsonValue('sideswapPegIn')
  sideswapPegIn,
  @JsonValue('sideswapPegOut')
  sideswapPegOut,
  @JsonValue('boltzSwap')
  boltzSwap,
  @JsonValue('boltzReverseSwap')
  boltzReverseSwap,
  @JsonValue('sideshiftSwap')
  sideshiftSwap,
  @JsonValue('aquaSend')
  aquaSend,
}

extension TransactionDbModelTypeExtension on TransactionDbModelType {
  bool get isBoltzSwap =>
      this == TransactionDbModelType.boltzSwap ||
      this == TransactionDbModelType.boltzReverseSwap;
}

@freezed
@Collection(ignore: {'copyWith'})
class TransactionDbModel with _$TransactionDbModel {
  const TransactionDbModel._();

  @JsonSerializable()
  const factory TransactionDbModel({
    @Default(Isar.autoIncrement) int id,
    @JsonKey(required: true, disallowNullValue: true) required String txhash,
    @JsonKey(disallowNullValue: true) String? receiveAddress,
    @JsonKey(required: true, disallowNullValue: true) required String assetId,
    @Enumerated(EnumType.name) required TransactionDbModelType type,
    String? serviceOrderId,
    String? serviceAddress,
    @Default(false) bool isGhost,
    DateTime? ghostTxnCreatedAt,
    int? ghostTxnAmount,
    int? ghostTxnFee,
  }) = _TransactionDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory TransactionDbModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionDbModelFromJson(json);

  @Deprecated('Only used for migration, use `fromV2SwapResponse` instead')
  factory TransactionDbModel.fromBoltzSwap({
    required String txhash,
    required String assetId,
    required BoltzSwapData swap,
  }) {
    return TransactionDbModel(
      txhash: txhash,
      assetId: assetId,
      type: TransactionDbModelType.boltzSwap,
      serviceOrderId: swap.response.id,
      serviceAddress: swap.response.address,
    );
  }

  @Deprecated('Only used for migration, use `fromV2SwapResponse` instead')
  factory TransactionDbModel.fromBoltzRevSwap({
    required String txhash,
    required String assetId,
    required BoltzReverseSwapData swap,
  }) {
    return TransactionDbModel(
      txhash: txhash,
      assetId: assetId,
      type: TransactionDbModelType.boltzReverseSwap,
      serviceOrderId: swap.response.id,
      serviceAddress: swap.response.lockupAddress,
    );
  }

  factory TransactionDbModel.fromV2SwapResponse({
    required String txhash,
    required String assetId,
    required String settleAddress,
    required LbtcLnSwap swap,
  }) {
    return TransactionDbModel(
      txhash: txhash,
      assetId: assetId,
      type: swap.kind == SwapType.submarine
          ? TransactionDbModelType.boltzSwap
          : TransactionDbModelType.boltzReverseSwap,
      serviceOrderId: swap.id,
      serviceAddress: swap.scriptAddress,
      receiveAddress: settleAddress,
    );
  }

  factory TransactionDbModel.fromSideshiftOrder(
    SideshiftOrderStatusResponse order,
  ) {
    final isLiquidDeposit = order.depositNetwork == 'liquid';
    return TransactionDbModel(
      txhash: isLiquidDeposit ? order.depositHash! : order.settleHash!,
      assetId: isLiquidDeposit ? order.depositCoin! : order.settleCoin!,
      type: TransactionDbModelType.sideshiftSwap,
      serviceOrderId: order.id,
      serviceAddress:
          isLiquidDeposit ? order.depositAddress : order.settleAddress,
    );
  }
}

extension TransactionDbModelX on TransactionDbModel {
  bool get isAquaSend => type == TransactionDbModelType.aquaSend;
  bool get isSwap => type == TransactionDbModelType.sideswapSwap;
  bool get isPeg =>
      type == TransactionDbModelType.sideswapPegIn ||
      type == TransactionDbModelType.sideswapPegOut;
  bool get isPegIn => type == TransactionDbModelType.sideswapPegIn;
  bool get isPegOut => type == TransactionDbModelType.sideswapPegOut;
  bool get isBoltzSwap => type == TransactionDbModelType.boltzSwap;
  bool get isBoltzReverseSwap =>
      type == TransactionDbModelType.boltzReverseSwap;
}

extension IsarCollectionX<T> on IsarCollection<T> {
  Future<List<T>> all() => where().findAll();
}
