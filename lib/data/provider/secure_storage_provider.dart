import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageError {
  StorageError(this.message, {this.expected = false}) {
    if (!expected) {
      final trace = StackTrace.current;
      logger.e('Error: $message \n$trace');
    }
  }

  final String message;
  final bool expected;

  @override
  String toString() => message;
}

abstract class IStorage {
  Future<StorageError?> save({
    required String key,
    required String value,
  });

  Future<(String?, StorageError?)> get(
    String key,
  );

  Future<(Map<String, String>?, StorageError?)> getAll();

  Future<StorageError?> delete(
    String key,
  );

  Future<StorageError?> deleteAll();
}

class SecureStorage implements IStorage {
  final _storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
          accessibility: KeychainAccessibility.unlocked_this_device));

  @override
  Future<StorageError?> save({
    required String key,
    required String value,
  }) async {
    try {
      await _storage.write(
        key: key,
        value: value,
      );
      return null;
    } catch (e) {
      return StorageError(e.toString());
    }
  }

  @override
  Future<(String?, StorageError?)> get(
    String key,
  ) async {
    try {
      final value = await _storage.read(
        key: key,
      );

      if (value == null) throw 'Key is not in the storage';

      return (value, null);
    } catch (e) {
      return (
        null,
        StorageError(e.toString(), expected: e == 'Key is not in the storage')
      );
    }
  }

  @override
  Future<(Map<String, String>?, StorageError?)> getAll() async {
    try {
      final value = await _storage.readAll();
      return (value, null);
    } catch (e) {
      return (null, StorageError(e.toString()));
    }
  }

  @override
  Future<StorageError?> delete(
    String key,
  ) async {
    try {
      final _ = await _storage.delete(
        key: key,
      );

      return null;
    } catch (e) {
      return StorageError(e.toString());
    }
  }

  @override
  Future<StorageError?> deleteAll() async {
    try {
      await _storage.deleteAll();

      return null;
    } catch (e) {
      return StorageError(e.toString());
    }
  }
}

class StorageKeys {
  static const mnemonic = 'mnemonic';
}

final secureStorageProvider = Provider<IStorage>((_) => SecureStorage());
