import 'package:aqua/data/provider/fee_estimate_provider.dart';

class FeeRate {
  final TransactionPriority priority;
  final double rate;

  FeeRate(this.priority, this.rate);
}
