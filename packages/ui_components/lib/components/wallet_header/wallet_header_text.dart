/// Text strings required by [AquaWalletHeader].
///
/// This class encapsulates all the Text strings needed by the wallet
/// header component, making it independent of any specific Text system.
class WalletHeaderText {
  const WalletHeaderText({
    required this.receive,
    required this.send,
    required this.scan,
    required this.bitcoinPrice,
  });

  final String receive;
  final String send;
  final String scan;
  final String bitcoinPrice;
}
