import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/swaps/swaps.dart';
import 'package:boltz/boltz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:isar/isar.dart';

part 'transaction_model.freezed.dart';
part 'transaction_model.g.dart';

typedef SwapServiceDetails = ({String name, String link});

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

  SwapServiceDetails? swapServiceDetails([SwapServiceSource? serviceSource]) {
    return switch (this) {
      TransactionDbModelType.sideswapSwap ||
      TransactionDbModelType.sideswapPegIn ||
      TransactionDbModelType.sideswapPegOut =>
        (name: 'SideSwap', link: sideswapWebsite),
      TransactionDbModelType.boltzSwap ||
      TransactionDbModelType.boltzReverseSwap =>
        (
          name: 'Boltz',
          link: boltzWebsite,
        ),
      TransactionDbModelType.sideshiftSwap => serviceSource != null
          ? (
              name: serviceSource.displayName,
              link: serviceSource.serviceUrl(),
            )
          : (
              name: 'SideShift',
              link: sideshiftWebsite,
            ),
      _ => null,
    };
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
    @Enumerated(EnumType.name) SwapServiceSource? swapServiceSource,
    String? serviceAddress,
    int? estimatedFee,
    @Default(false) bool isGhost,
    DateTime? ghostTxnCreatedAt,
    int? ghostTxnAmount,

    //NOTE - The delivered amount for Sideswap LBTC ↔ USDt swaps and Boltz Submarine Swaps
    //This field stores the amount being sent/delivered in the swap,
    //while ghostTxnAmount stores the received amount.
    //Reserved for TransactionDbModelType.sideswapSwap and TransactionDbModelType.BoltzSwap
    int? ghostTxnSideswapDeliverAmount,
    int? ghostTxnFee,
    String? feeAssetId,
    String? note,
    String? walletId,
    double? exchangeRateAtExecution,
    String? currencyAtExecution,
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
    required String walletId,
    int? deliverAmount,
  }) {
    return TransactionDbModel(
      txhash: txhash,
      assetId: assetId,
      walletId: walletId,
      type: swap.kind == SwapType.submarine
          ? TransactionDbModelType.boltzSwap
          : TransactionDbModelType.boltzReverseSwap,
      serviceOrderId: swap.id,
      serviceAddress: swap.scriptAddress,
      receiveAddress: settleAddress,
      ghostTxnAmount: swap.outAmount.toInt(),
      ghostTxnCreatedAt: DateTime.now(),
      ghostTxnSideswapDeliverAmount: deliverAmount,
    );
  }

  factory TransactionDbModel.fromSwapOrderDbModel(
    SwapOrderDbModel swapOrder, {
    required String walletId,
    bool isGhost = false,
  }) {
    return TransactionDbModel(
      txhash: swapOrder.onchainTxHash ?? '',
      walletId: walletId,
      receiveAddress: swapOrder.settleAddress,
      assetId: swapOrder.toAsset,
      type: TransactionDbModelTypeExtension.fromServiceSource(
          swapOrder.serviceType),
      serviceOrderId: swapOrder.orderId,
      swapServiceSource: swapOrder.serviceType,
      serviceAddress: swapOrder.depositAddress,
      isGhost: isGhost,
      ghostTxnCreatedAt: swapOrder.createdAt,
      ghostTxnAmount: int.tryParse(swapOrder.settleAmount ?? '0'),
      ghostTxnFee: int.tryParse(swapOrder.serviceFeeValue),
      note: 'Pending swap transaction',
    );
  }

  //TODO: Replace PegOrderDbModel  with SwapOrderDbModel when SideswapPegs are migrated to the new swap interface.
  @Deprecated(
      'Replace PegOrderDbModel  with SwapOrderDbModel when SideswapPegs are migrated to the new swap interface.')
  factory TransactionDbModel.fromPegOrderDbModel(
    PegOrderDbModel pegOrder, {
    required String walletId,
    bool isGhost = false,
  }) {
    return TransactionDbModel(
      txhash: pegOrder.txhash ?? '',
      walletId: walletId,
      receiveAddress: pegOrder.receiveAddress,
      assetId: pegOrder.isPegIn ? Asset.btc().id : Asset.lbtc().id,
      type: pegOrder.isPegIn
          ? TransactionDbModelType.sideswapPegIn
          : TransactionDbModelType.sideswapPegOut,
      serviceOrderId: pegOrder.orderId,
      serviceAddress: pegOrder.depositAddress,
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
  bool get isBoltz =>
      type == TransactionDbModelType.boltzSwap ||
      type == TransactionDbModelType.boltzReverseSwap ||
      type == TransactionDbModelType.boltzSendFailed ||
      type == TransactionDbModelType.boltzRefund;
  bool get isBoltzSwap => type == TransactionDbModelType.boltzSwap;
  bool get isBoltzReverseSwap =>
      type == TransactionDbModelType.boltzReverseSwap;
  bool get isTopUp => type == TransactionDbModelType.moonTopUp;
  bool get isUSDtSwap => type == TransactionDbModelType.sideshiftSwap;
  bool get isLightning => assetId == AssetIds.lightning || isBoltz;
  bool get isAnySwap => isPeg || isSwap || isUSDtSwap;

  String? get swapServiceName =>
      type?.swapServiceDetails(swapServiceSource)?.name;

  String? get swapServiceUrl =>
      type?.swapServiceDetails(swapServiceSource)?.link;
}

extension IsarCollectionX<T> on IsarCollection<T> {
  Future<List<T>> all() => where().findAll();
}
