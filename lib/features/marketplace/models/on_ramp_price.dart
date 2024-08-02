enum OnRampPriceType { integration, reference }

class OnRampPrice {
  OnRampPrice({
    required this.price,
    required this.currencyCode,
    required this.type,
  });

  final String price;
  final String currencyCode;
  final OnRampPriceType type;
}
