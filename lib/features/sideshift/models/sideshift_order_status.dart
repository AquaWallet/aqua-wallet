import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/utils/utils.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sideshift_order_status.freezed.dart';
part 'sideshift_order_status.g.dart';

enum OrderStatus {
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

extension OrderStatusExtension on OrderStatus {
  String localizedString(BuildContext context) {
    switch (this) {
      case OrderStatus.waiting:
        return context.loc.sideshiftOrderStatusWaiting;
      case OrderStatus.pending:
        return context.loc.sideshiftOrderStatusPending;
      case OrderStatus.processing:
        return context.loc.sideshiftOrderStatusProcessing;
      case OrderStatus.review:
        return context.loc.sideshiftOrderStatusReview;
      case OrderStatus.settling:
        return context.loc.sideshiftOrderStatusSettling;
      case OrderStatus.settled:
        return context.loc.sideshiftOrderStatusSettled;
      case OrderStatus.refund:
        return context.loc.sideshiftOrderStatusRefund;
      case OrderStatus.refunding:
        return context.loc.sideshiftOrderStatusRefunding;
      case OrderStatus.refunded:
        return context.loc.sideshiftOrderStatusRefunded;
      case OrderStatus.expired:
        return context.loc.sideshiftOrderStatusExpired;
      default:
        return context.loc.sideshiftOrderStatusUnknown;
    }
  }

  bool get isPending {
    return this == OrderStatus.waiting ||
        this == OrderStatus.pending ||
        this == OrderStatus.processing ||
        this == OrderStatus.review ||
        this == OrderStatus.settling;
  }

  bool get isFailed {
    return this == OrderStatus.refund ||
        this == OrderStatus.refunding ||
        this == OrderStatus.refunded;
  }

  bool get isSuccess {
    return this == OrderStatus.settled;
  }

  bool get isFinal {
    return this == OrderStatus.refunded || this == OrderStatus.settled;
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
    OrderType? type,
    String? depositAmount,
    String? settleAmount,
    DateTime? expiresAt,
    OrderStatus? status,
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
