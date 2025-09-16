import 'package:coin_cz/data/provider/fiat_provider.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:decimal/decimal.dart';

final _conversionProvider = Provider.family<ConversionProvider, (Asset, int)>(
    (ref, arguments) => ConversionProvider(ref, arguments));

class ConversionProvider {
  ConversionProvider(this._ref, this._arguments);

  final ProviderRef _ref;
  final (Asset, int) _arguments;

  Stream<SatoshiToFiatConversionModel> _conversion() => _ref
      .read(fiatProvider)
      .satoshiToReferenceCurrencyStream(_arguments.$1, _arguments.$2);
}

final _conversionFiatProvider = Provider.family
    .autoDispose<ConversionFiatProvider, (Asset, Decimal)>(
        (ref, arguments) => ConversionFiatProvider(ref, arguments));

class ConversionFiatProvider {
  ConversionFiatProvider(this._ref, this._arguments);

  final AutoDisposeProviderRef _ref;
  final (Asset, Decimal) _arguments;

  Stream<String> _conversion() => _ref
      .read(fiatProvider)
      .fiatToSatoshiStream(_arguments.$1, _arguments.$2.toString());
}

final _conversionStreamProvider =
    StreamProvider.family<SatoshiToFiatConversionModel, (Asset, int)>(
        (ref, arguments) async* {
  yield* ref.watch(_conversionProvider(arguments))._conversion();
});

final conversionProvider =
    Provider.family<SatoshiToFiatConversionModel?, (Asset, int)>(
        (ref, arguments) {
  return ref.watch(_conversionStreamProvider(arguments)).asData?.value;
});

final _conversionFiatStreamProvider = StreamProvider.family
    .autoDispose<String, (Asset, Decimal)>((ref, arguments) async* {
  yield* ref.watch(_conversionFiatProvider(arguments))._conversion();
});

final conversionFiatProvider =
    Provider.family.autoDispose<String?, (Asset, Decimal)>((ref, arguments) {
  return ref.watch(_conversionFiatStreamProvider(arguments)).asData?.value;
});
