import 'package:aqua/features/boltz/boltz.dart';
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
  }) = _TransactionDbModel;

  @override
  // ignore: recursive_getters
  Id get id => id;

  factory TransactionDbModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionDbModelFromJson(json);

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
}

extension TransactionDbModelX on TransactionDbModel {
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

extension TransactionDbModelCollectionX on IsarCollection<TransactionDbModel> {
  Future<List<TransactionDbModel>> all() => where().findAll();
}
