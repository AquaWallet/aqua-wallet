import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:rxdart/rxdart.dart';

final _logger = CustomLogger(FeatureFlag.statusManager);

final connectivityStatusProvider = StreamProvider<bool>((_) => Connectivity()
    .onConnectivityChanged
    .doOnEach((event) => _logger.info("Connection status changed: $event"))
    .map((result) => result.any((e) => e != ConnectivityResult.none))
    .distinct());
