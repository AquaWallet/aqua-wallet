/// Text strings required by [AquaDebitCard].
///
/// This class encapsulates all the Text strings needed by the debit card
/// component, making it independent of any specific Text system.
class DebitCardText {
  const DebitCardText({
    required this.reloadable,
    required this.nonReloadable,
    required this.expiryDate,
    required this.cvv,
  });

  final String reloadable;
  final String nonReloadable;
  final String expiryDate;
  final String cvv;
}
