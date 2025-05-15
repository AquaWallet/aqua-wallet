import 'package:aqua/data/models/database/peg_order_model.dart';
import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/features/swaps/swaps.dart';
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
  //TODO: This covers all usdtSwaps and should be migrated to 'usdtSwap' at some point. Legacy from when we only had sideshift
  @JsonValue('sideshiftSwap')
  sideshiftSwap,
  @JsonValue('moonTopUp')
  moonTopUp,
  @JsonValue('aquaSend')
  aquaSend,
  @JsonValue('boltzRefund')
  boltzRefund,
  @JsonValue('boltzSendFailed')
  boltzSendFailed;
}

extension TransactionDbModelTypeExtension on TransactionDbModelType {
  bool get isBoltzSwap =>
      this == TransactionDbModelType.boltzSwap ||
      this == TransactionDbModelType.boltzReverseSwap;

  bool get isPeg =>
      this == TransactionDbModelType.sideswapPegIn ||
      this == TransactionDbModelType.sideswapPegOut;

  bool get isUSDtSwap => this == TransactionDbModelType.sideshiftSwap;

  // Determine the TransactionDbModelType from the SwapServiceSource
  static TransactionDbModelType fromServiceSource(SwapServiceSource source) {
    switch (source) {
      case SwapServiceSource.sideshift:
      case SwapServiceSource.changelly:
        return TransactionDbModelType.sideshiftSwap;
      default:
        throw ArgumentError('Unknown SwapServiceSource: $source');
    }
  }
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
    String? assetId,
    @Enumerated(EnumType.name) TransactionDbModelType? type,
    String? serviceOrderId,
    String? serviceAddress,
    int? estimatedFee,
    @Default(false) bool isGhost,
    DateTime? ghostTxnCreatedAt,
    int? ghostTxnAmount,
    int? ghostTxnFee,
    String? note,
  }) = _TransactionDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory TransactionDbModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionDbModelFromJson(json);

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

  factory TransactionDbModel.fromSwapOrderDbModel(SwapOrderDbModel swapOrder,
      {bool isGhost = false}) {
    return TransactionDbModel(
      txhash: swapOrder.orderId,
      receiveAddress: swapOrder.settleAddress,
      assetId: swapOrder.toAsset,
      type: TransactionDbModelTypeExtension.fromServiceSource(
          swapOrder.serviceType),
      serviceOrderId: swapOrder.orderId,
      serviceAddress: swapOrder.settleAddress,
      isGhost: isGhost,
      ghostTxnCreatedAt: swapOrder.createdAt,
      ghostTxnAmount: int.tryParse(swapOrder.settleAmount ?? '0'),
      ghostTxnFee: int.tryParse(swapOrder.serviceFeeValue),
      note: 'Pending swap transaction',
    );
  }

  @Deprecated(
      'TODO: Replace PegOrderDbModel  with SwapOrderDbModel when SideswapPegs are migrated to the new swap interface.')
  factory TransactionDbModel.fromPegOrderDbModel(PegOrderDbModel pegOrder,
      {bool isGhost = false}) {
    return TransactionDbModel(
      txhash: pegOrder.orderId,
      receiveAddress: null,
      assetId: null,
      type: pegOrder.isPegIn
          ? TransactionDbModelType.sideswapPegIn
          : TransactionDbModelType.sideswapPegOut,
      serviceOrderId: pegOrder.orderId,
      serviceAddress:
          null, //null because addresses weren't stored in PegOrderDbModel. Switching to SwapOrderDbModel will fix.
      isGhost: isGhost,
      ghostTxnCreatedAt: pegOrder.createdAt,
      ghostTxnAmount: pegOrder.amount,
      ghostTxnFee: null,
    );
  }
}

extension TransactionDbModelX on TransactionDbModel {
  bool get isAquaSend => type == TransactionDbModelType.aquaSend;
  bool get isBoltzRefund => type == TransactionDbModelType.boltzRefund;
  bool get isBoltzSendFailed => type == TransactionDbModelType.boltzSendFailed;
  bool get isSwap => type == TransactionDbModelType.sideswapSwap;
  bool get isPeg =>
      type == TransactionDbModelType.sideswapPegIn ||
      type == TransactionDbModelType.sideswapPegOut;
  bool get isPegIn => type == TransactionDbModelType.sideswapPegIn;
  bool get isPegOut => type == TransactionDbModelType.sideswapPegOut;
  bool get isBoltzSwap => type == TransactionDbModelType.boltzSwap;
  bool get isBoltzReverseSwap =>
      type == TransactionDbModelType.boltzReverseSwap;
  bool get isTopUp => type == TransactionDbModelType.moonTopUp;
  bool get isUSDtSwap => type == TransactionDbModelType.sideshiftSwap;
}

extension IsarCollectionX<T> on IsarCollection<T> {
  Future<List<T>> all() => where().findAll();
}
