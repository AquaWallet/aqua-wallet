import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/models/sideshift_order.dart';
import 'package:aqua/features/swaps/models/swap_models.dart';
import 'package:aqua/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift_order_status.freezed.dart';
part 'sideshift_order_status.g.dart';

enum SideshiftOrderStatus {
  @JsonValue('waiting')
  waiting,
  @JsonValue('pending')
  pending,
  @JsonValue('processing')
  processing,
  @JsonValue('review')
  review,
  @JsonValue('settling')
  settling,
  @JsonValue('settled')
  settled,
  @JsonValue('refund')
  refund,
  @JsonValue('refunding')
  refunding,
  @JsonValue('refunded')
  refunded,
  @JsonValue('expired')
  expired,
}

extension SideshiftOrderStatusExt on SideshiftOrderStatus {
  String localizedString(BuildContext context) {
    switch (this) {
      case SideshiftOrderStatus.waiting:
        return context.loc.waiting;
      case SideshiftOrderStatus.pending:
        return context.loc.assetTransactionDetailsPending;
      case SideshiftOrderStatus.processing:
        return context.loc.processing;
      case SideshiftOrderStatus.review:
        return context.loc.sideshiftOrderStatusReview;
      case SideshiftOrderStatus.settling:
        return context.loc.sideshiftOrderStatusSettling;
      case SideshiftOrderStatus.settled:
        return context.loc.sideshiftOrderStatusSettled;
      case SideshiftOrderStatus.refund:
        return context.loc.refund;
      case SideshiftOrderStatus.refunding:
        return context.loc.refunding;
      case SideshiftOrderStatus.refunded:
        return context.loc.refunded;
      case SideshiftOrderStatus.expired:
        return context.loc.expired;
      default:
        return context.loc.unknown;
    }
  }

  bool get isPending {
    return this == SideshiftOrderStatus.waiting ||
        this == SideshiftOrderStatus.pending ||
        this == SideshiftOrderStatus.processing ||
        this == SideshiftOrderStatus.review ||
        this == SideshiftOrderStatus.settling;
  }

  bool get isFailed {
    return this == SideshiftOrderStatus.refund ||
        this == SideshiftOrderStatus.refunding ||
        this == SideshiftOrderStatus.refunded;
  }

  bool get isSuccess {
    return this == SideshiftOrderStatus.settled;
  }

  bool get isFinal {
    return this == SideshiftOrderStatus.refunded ||
        this == SideshiftOrderStatus.settled;
  }

  SwapOrderStatus toSwapOrderStatus() {
    switch (this) {
      case SideshiftOrderStatus.waiting:
        return SwapOrderStatus.waiting;
      case SideshiftOrderStatus.pending:
        return SwapOrderStatus.waiting;
      case SideshiftOrderStatus.processing:
        return SwapOrderStatus.processing;
      case SideshiftOrderStatus.review:
        return SwapOrderStatus.processing;
      case SideshiftOrderStatus.settling:
        return SwapOrderStatus.sending;
      case SideshiftOrderStatus.settled:
        return SwapOrderStatus.completed;
      case SideshiftOrderStatus.refund:
        return SwapOrderStatus.failed;
      case SideshiftOrderStatus.refunding:
        return SwapOrderStatus.refunding;
      case SideshiftOrderStatus.refunded:
        return SwapOrderStatus.refunded;
      case SideshiftOrderStatus.expired:
        return SwapOrderStatus.expired;
      default:
        return SwapOrderStatus.waiting;
    }
  }

  static SideshiftOrderStatus fromSwapOrderStatus(SwapOrderStatus status) {
    switch (status) {
      case SwapOrderStatus.waiting:
        return SideshiftOrderStatus.waiting;
      case SwapOrderStatus.processing:
        return SideshiftOrderStatus.processing;
      case SwapOrderStatus.completed:
        return SideshiftOrderStatus.settled;
      case SwapOrderStatus.failed:
        return SideshiftOrderStatus.refund;
      case SwapOrderStatus.refunding:
        return SideshiftOrderStatus.refunding;
      case SwapOrderStatus.refunded:
        return SideshiftOrderStatus.refunded;
      case SwapOrderStatus.expired:
        return SideshiftOrderStatus.expired;
      case SwapOrderStatus.exchanging:
        return SideshiftOrderStatus.processing;
      case SwapOrderStatus.sending:
        return SideshiftOrderStatus.settling;
      default:
        return SideshiftOrderStatus.waiting;
    }
  }
}

@freezed
class SideshiftOrderStatusResponse with _$SideshiftOrderStatusResponse {
  factory SideshiftOrderStatusResponse({
    String? id,
    DateTime? createdAt,
    String? depositCoin,
    String? settleCoin,
    String? depositNetwork,
    String? settleNetwork,
    String? depositAddress,
    String? settleAddress,
    String? depositMin,
    String? depositMax,
    SideshiftOrderType? orderType,
    String? depositAmount,
    String? settleAmount,
    DateTime? expiresAt,
    SideshiftOrderStatus? status,
    DateTime? updatedAt,
    String? depositHash,
    String? settleHash,
    DateTime? depositReceivedAt,
    String? rate,

    /// The onchain tx hash for the deposit
    String? onchainTxHash,
  }) = _SideshiftOrderStatusResponse;

  factory SideshiftOrderStatusResponse.fromJson(Map<String, dynamic> json) =>
      _$SideshiftOrderStatusResponseFromJson(json);
}
