import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aqua/data/models/database/peg_order_model.dart';
import 'package:aqua/data/models/database/swap_order_model.dart';
import 'package:aqua/data/models/database/transaction_model.dart';
import 'package:aqua/features/boltz/models/db_models.dart';
import 'package:aqua/logger.dart';
import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';

const _kExportFileName = 'aqua_db_export.json';
const _kExportVersion = 1;
const _kDebounce = Duration(seconds: 5);

final _logger = CustomLogger(FeatureFlag.isar);

typedef _ExportArgs = ({String path, Map<String, dynamic> data});

@visibleForTesting
Future<void> encodeAndWriteExport(_ExportArgs args) async {
  final json = jsonEncode(args.data);
  final tmpPath = '${args.path}.tmp';
  final tmpFile = File(tmpPath);
  await tmpFile.writeAsString(json, flush: true);
  await tmpFile.rename(args.path);
}

class IsarExportService with WidgetsBindingObserver {
  IsarExportService(
    this._isar, {
    Future<Directory> Function()? getExportDir,
    Duration debounce = _kDebounce,
  })  : _getExportDir = getExportDir ?? getApplicationDocumentsDirectory,
        _debounce = debounce;

  final Isar _isar;
  final Future<Directory> Function() _getExportDir;
  final Duration _debounce;

  StreamSubscription<void>? _watchSubscription;
  bool _disposed = false;
  bool _exporting = false;
  bool _pendingAfterGuard = false;

  void start() {
    WidgetsBinding.instance.addObserver(this);
    _startWatching();
  }

  void dispose() {
    _disposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _watchSubscription?.cancel();
  }

  void _startWatching() {
    final merged = StreamGroup.merge<void>([
      _isar.transactionDbModels.watchLazy(),
      _isar.swapOrderDbModels.watchLazy(),
      _isar.boltzSwapDbModels.watchLazy(),
      _isar.pegOrderDbModels.watchLazy(),
    ]);

    _watchSubscription =
        merged.debounceTime(_debounce).listen((_) => _triggerExport());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _triggerExport();
    }
  }

  Future<void> exportNow() => _triggerExport();

  Future<void> _triggerExport() async {
    if (_disposed) return;
    if (_exporting) {
      _pendingAfterGuard = true;
      return;
    }
    _exporting = true;

    try {
      await _runExport();
    } finally {
      _exporting = false;
      if (_pendingAfterGuard) {
        _pendingAfterGuard = false;
        unawaited(_triggerExport());
      }
    }
  }

  Future<void> _runExport() async {
    try {
      final txns = await _isar.transactionDbModels.where().exportJson();
      final swapOrders = await _isar.swapOrderDbModels.where().exportJson();
      final boltzSwaps = await _isar.boltzSwapDbModels.where().exportJson();
      final pegOrders = await _isar.pegOrderDbModels.where().exportJson();

      final dir = await _getExportDir();
      final exportPath = '${dir.path}/$_kExportFileName';

      final data = <String, dynamic>{
        'version': _kExportVersion,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'collections': {
          'transactions': txns,
          'swapOrders': swapOrders,
          'boltzSwaps': boltzSwaps,
          'pegOrders': pegOrders,
        },
      };

      await compute(encodeAndWriteExport, (path: exportPath, data: data));
      _logger.debug('[Isar] Export written to $exportPath');
    } on IsarError catch (e, st) {
      _logger.warning('[Isar] Export Isar read error', e, st);
    } catch (e, st) {
      _logger.warning('[Isar] Export failed', e, st);
      try {
        final dir = await _getExportDir();
        final tmp = File('${dir.path}/$_kExportFileName.tmp');
        if (await tmp.exists()) await tmp.delete();
      } catch (_) {}
    }
  }
}
