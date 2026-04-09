import 'package:flutter/foundation.dart';
import 'package:talker_flutter/talker_flutter.dart';

enum FeatureFlag {
  autoLock('AutoLock'),
  biometric('Biometric'),
  dataTransfer('DataTransfer'),
  aquaNodeStatus('AquaNodeStatus'),
  initAppProvider('InitAppProvider'),
  lifecycle('Lifecycle'),
  onramp('Onramp'),
  restore('Restore'),
  lnurl('LNURL'),
  boltz('BOLTZ'),
  boltzStorage('BoltzStorage'),
  btcDirect('BTCDirect'),
  statusManager('StatusManager'),
  swap('Swap'),
  swapOrderStorage('SwapOrderStorage'),
  sideswap('Sideswap'),
  sideshift('SideShift'),
  sideshiftOrderStorage('SideshiftOrderStorage'),
  peg('Peg'),
  pokerchip('Pokerchip'),
  subaccounts('Subaccounts'),
  env('ENV'),
  export('Export'),
  receive('Receive'),
  send('Send'),
  transactions('Transactions'),
  transactionStorage('TransactionStorage'),
  fees('Fees'),
  isar('Isar'),
  qr('QR'),
  textScan('TextScan'),
  electrs('Electrs'),
  network('Network'),
  notifications('Notifications'),
  tx('TX'),
  user('User'),
  unifiedBalance('UnifiedBalance'),
  jan3Account('Jan3Account'),
  jan3AuthToken('Jan3AuthToken'),
  debitCard('DebitCard'),
  multiWallet('MultiWallet');

  const FeatureFlag(this.value);

  final String value;
}

// to see logs only for selected feature flags -> add them in the list
final List<FeatureFlag> enabledLogFlags = [];

/// This filter checks that message contains a feature flag
class FeatureFilter implements TalkerFilter {
  const FeatureFilter(this.enabledFeatureFlags);

  final List<FeatureFlag> enabledFeatureFlags;

  @override
  bool filter(TalkerData item) {
    final lowercaseMessage = item.message?.toLowerCase();

    if (lowercaseMessage == null) {
      return false;
    }

    for (final featureFlag in enabledFeatureFlags) {
      final featureFlagFormatted = "[${featureFlag.value.toLowerCase()}]";

      if (lowercaseMessage.contains(featureFlagFormatted)) {
        return true;
      }
    }

    return false;
  }
}

String formatFeatureFlag(FeatureFlag? feature) {
  return feature != null ? "[${feature.value}]" : '';
}

class CustomLogger {
  factory CustomLogger(FeatureFlag? feature) {
    _customLogger.feature = feature;
    return _customLogger;
  }

  CustomLogger._internal();

  static final CustomLogger _customLogger = CustomLogger._internal();

  static const String appName = 'Aqua';
  FeatureFlag? feature;

  Talker internalLogger = TalkerFlutter.init(
      filter: kDebugMode && enabledLogFlags.isNotEmpty
          ? FeatureFilter(enabledLogFlags)
          : null);

  void debug(dynamic message, [Object? exception, StackTrace? stackTrace]) {
    internalLogger.debug('$appName: ${formatFeatureFlag(feature)} $message');
  }

  void info(dynamic message, [Object? exception, StackTrace? stackTrace]) {
    internalLogger.info('$appName: ${formatFeatureFlag(feature)} $message');
  }

  void warning(dynamic message, [Object? exception, StackTrace? stackTrace]) {
    internalLogger.warning('$appName: ${formatFeatureFlag(feature)} $message');
  }

  void error(dynamic message, [Object? exception, StackTrace? stackTrace]) {
    internalLogger.error('$appName: ${formatFeatureFlag(feature)} $message',
        exception, stackTrace);
  }
}

CustomLogger logger = CustomLogger(null);
