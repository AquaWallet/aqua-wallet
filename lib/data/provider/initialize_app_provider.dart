import 'package:aqua/logger.dart';
import 'package:aqua/gdk.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/data/provider/bitcoin_provider.dart';
import 'package:aqua/data/provider/liquid_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

final initAppProvider =
    Provider.autoDispose<InitAppProvider>((ref) => InitAppProvider(ref));

class InitAppProvider {
  InitAppProvider(this.ref) {
    ref.onDispose(() {
      _initAppSubject.close();
    });
  }

  final AutoDisposeProviderRef ref;

  late final Stream<AsyncValue<void>> initAppStream = _initAppSubject
      .startWith(null)
      .switchMap((_) => Rx.zipList([
            getApplicationSupportDirectory()
                .then((dir) async {
                  final config = GdkConfig(
                      dataDir: dir.absolute.path,
                      logLevel: GdkConfigLogLevelEnum.info);
                  final libGdk = LibGdk();
                  return await libGdk.initGdk(config);
                })
                .asStream()
                .switchMap((_) => Rx.zipList([
                      ref
                          .read(liquidProvider)
                          .init()
                          .then<bool>((result) =>
                              result ? Future.value(result) : throw Exception())
                          .asStream(),
                      ref
                          .read(bitcoinProvider)
                          .init()
                          .then<bool>((result) =>
                              result ? Future.value(result) : throw Exception())
                          .asStream(),
                    ])),
          ])
              .doOnData((_) => logger.d('Backends initialization done'))
              .map<AsyncValue<void>>((_) {
                return const AsyncValue.data(null);
              })
              .startWith(const AsyncValue.loading())
              .onErrorReturnWith(
                  (error, stackTrace) => AsyncValue.error(error, stackTrace)))
      .shareReplay(maxSize: 1);

  final PublishSubject<void> _initAppSubject = PublishSubject();
}
