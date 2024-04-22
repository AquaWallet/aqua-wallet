import 'package:aqua/data/provider/electrs_provider.dart';

class FeeRate {
  final TransactionPriority priority;
  final double rate;

  FeeRate(this.priority, this.rate);
}
