class ExchangeRate {
  final String name;
  final String sign;
  final String symbol;

  String get displayName => '$name ($sign $symbol)';

  const ExchangeRate(this.name, this.sign, this.symbol);
}
