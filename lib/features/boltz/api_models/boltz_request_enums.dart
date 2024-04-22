//ANCHOR - SwapType

enum SwapType { submarine, reversesubmarine }

//ANCHOR - OrderSide

enum OrderSide { buy, sell }

//ANCHOR - PairId
enum PairId {
  lbtcBtc('L-BTC/BTC');

  final String jsonValue;

  const PairId(this.jsonValue);

  static PairId? getByJsonValue(String jsonValue) =>
      PairId.values.firstWhere((pairId) => pairId.jsonValue == jsonValue);
}
