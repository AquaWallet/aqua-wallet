import 'package:aqua/features/settings/settings.dart';

class PokerchipBalanceState {
  PokerchipBalanceState({
    required this.address,
    required this.balance,
    required this.explorerLink,
    required this.asset,
  });

  final String address;
  final String balance;
  final String explorerLink;
  final Asset asset;
}
