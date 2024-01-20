import 'package:aqua/data/provider/aqua_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

extension RefExt on Ref {
  // The AQUA provider follows this pattern throughout the codebase where
  // boolean preferences are read by calling a method on either the GDK SDK or
  // native platform channels and the result depends on whether the property
  // exists or not. This is evaluated by by checking whether the function call
  // throws an error or not.
  //
  // This utility method tries to abstract away that confusing pattern.
  Future<bool> readAquaBool(Future<void> Function(AquaProvider p) fn) {
    return fn(read(aquaProvider)).then((_) => true).onError((_, __) => false);
  }
}
