import "dart:math";
import "package:flutter/foundation.dart";

/// Generate random 32 bytes
Uint8List generateRandom32Bytes() {
  var random = Random.secure();
  var seed = List<int>.generate(32, (_) => random.nextInt(256));
  return Uint8List.fromList(seed);
}
