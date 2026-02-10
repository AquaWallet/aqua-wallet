import 'dart:convert';

import 'package:aqua/data/models/cache_entry.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A simple key-value cache service for storing and retrieving primitive values.
// Currently being used for storing BTC price and user account balances.

enum CacheKey {
  btcPrice,
  btcPriceCurrency,
  btcPriceHistory,
}

class KeyValueCacheService {
  KeyValueCacheService(this._prefs);

  final SharedPreferences _prefs;

  static const kCacheExpiryInHours = 1;

  Future<void> save(CacheKey key, String value) async {
    final entry = CacheEntry(value: value, timestamp: DateTime.now());
    await _prefs.setString(
      key.name,
      jsonEncode(entry.toJson()),
    );
  }

  CacheEntry? get(CacheKey key) {
    final jsonString = _prefs.getString(key.name);
    if (jsonString == null) {
      return null;
    }
    try {
      final jsonMap = jsonDecode(jsonString) as Map<String, dynamic>;
      final item = CacheEntry.fromJson(jsonMap);
      final isCacheFresh = DateTime.now().difference(item.timestamp).inHours <
          KeyValueCacheService.kCacheExpiryInHours;
      return isCacheFresh ? item : null;
    } catch (e) {
      logger.error('Error deserializing CacheEntry for key $key', e);
      return null;
    }
  }

  Future<bool> remove(CacheKey key) async {
    return await _prefs.remove(key.name);
  }
}

final keyValueCacheServiceProvider = Provider<KeyValueCacheService>((ref) {
  final prefs = ref.read(sharedPreferencesProvider);
  return KeyValueCacheService(prefs);
});
