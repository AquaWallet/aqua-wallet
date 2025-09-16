import 'package:coin_cz/data/models/network_amount.dart';
import 'package:coin_cz/features/settings/settings.dart';

class PokerchipBalanceState {
  PokerchipBalanceState({
    required this.address,
    required this.balance,
    required this.networkAmount,
    required this.explorerLink,
    required this.asset,
  });

  final String address;
  final String balance;
  final NetworkAmount networkAmount;
  final String explorerLink;
  final Asset asset;
}
