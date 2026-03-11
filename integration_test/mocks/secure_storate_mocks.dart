import 'package:mocktail/mocktail.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';

class MockSecureStorage extends SecureStorage with Mock {
  final Map _mockData;

  /// Constructor to initialize default values for storage keys.
  MockSecureStorage()
      : _mockData = {
          StorageKeys.mnemonic: (
            'filter business whip tray vacant ritual beef gallery bottom crucial speed liar',
            null
          ),
          StorageKeys.pinFailedAttempts: ('0', null), // Default to "0" attempts
          StorageKeys.pinLockedAt: (DateTime.now().toIso8601String(), null),
        };

  /// Method to set mock data for a specific key dynamically.
  void setMockData(String key, (String?, StorageError?) value) {
    _mockData[key] = value;
  }

  /// Override to fetch mock data for a given key.
  @override
  Future<(String?, StorageError?)> get(String key) async {
    return _mockData[key] ?? (null, null);
  }

  /// Override to save data for a given key.
  @override
  Future<StorageError?> save({
    required String key,
    required String value,
  }) async {
    _mockData[key] = (value, null);
    return null;
  }

  /// Override to delete data for a given key.
  @override
  Future<StorageError?> delete(String key) async {
    _mockData.remove(key);
    return null;
  }

  /// Method to reset all keys to default values (if needed).
  void resetMockData() {
    _mockData[StorageKeys.mnemonic] = (
      'filter business whip tray vacant ritual beef gallery bottom crucial speed liar',
      null
    );
    _mockData[StorageKeys.pinFailedAttempts] = ('0', null);
    _mockData[StorageKeys.pinLockedAt] =
        (DateTime.now().toIso8601String(), null);
  }
}
