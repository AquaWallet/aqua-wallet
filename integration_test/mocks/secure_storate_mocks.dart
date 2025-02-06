import 'package:mocktail/mocktail.dart';
import 'package:aqua/data/provider/secure_storage/secure_storage_provider.dart';

class MockSecureStorage extends SecureStorage with Mock {
  final Map<String, (String?, StorageError?)> mnemonicMockData;

  MockSecureStorage(
      {(String?, StorageError?) defaultValue = (
        'filter business whip tray vacant ritual beef gallery bottom crucial speed liar',
        null
      )})
      : mnemonicMockData = {StorageKeys.mnemonic: defaultValue};

  void setMockData(String key, (String?, StorageError?) value) {
    mnemonicMockData[key] = value;
  }

  @override
  Future<(String?, StorageError?)> get(String key) {
    return Future.value(
        mnemonicMockData[key] ?? mnemonicMockData[StorageKeys.mnemonic]);
  }
}

//'filter business whip tray vacant ritual beef gallery bottom crucial speed liar',