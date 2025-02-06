import 'package:aqua/features/changelly/models/changelly_models.dart';
import 'package:decimal/decimal.dart';

// These fees are the combined Changelly service fee + our service fee.
// However, these grossly underestimate the actual fee because the spread is very wide.
// THEREFORE, should use the difference between deposit and settle amount in order to calculate ACTUAL FEE.
class ChangellyFees {
  final ChangellyOrderType type;

  const ChangellyFees(this.type);

  Decimal get percentageFee {
    switch (type) {
      case ChangellyOrderType.float:
        return Decimal.parse('0.002'); // 0.2%
      case ChangellyOrderType.fixed:
        return Decimal.parse('0.004'); // 0.4%
    }
  }
}
