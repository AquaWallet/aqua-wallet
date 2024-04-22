/// Converts a list of character positions in the bech32 alphabet ("words")
/// to binary data.
List<int> fromWords(List<int> words) {
  final res = convert(words, 5, 8, false);
  return res;
}

/// Taken from bech32 (bitcoinjs): https://github.com/bitcoinjs/bech32
List<int> convert(List<int> data, int inBits, int outBits, bool pad) {
  var value = 0;
  var bits = 0;
  var maxV = (1 << outBits) - 1;

  var result = <int>[];
  for (var i = 0; i < data.length; ++i) {
    value = (value << inBits) | data[i];
    bits += inBits;

    while (bits >= outBits) {
      bits -= outBits;
      result.add((value >> bits) & maxV);
    }
  }

  if (pad) {
    if (bits > 0) {
      result.add((value << (outBits - bits)) & maxV);
    }
  } else {
    if (bits >= inBits) {
      throw Exception('Excess padding');
    }

    if ((value << (outBits - bits)) & maxV > 0) {
      throw Exception('Non-zero padding');
    }
  }

  return result;
}
