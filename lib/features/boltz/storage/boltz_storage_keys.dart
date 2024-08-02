class BoltzStorageKeys {
  static const normalSwapPrefsPrefix = 'boltzNormalData_';
  static const reverseSwapPrefsPrefix = 'boltzData_';
  static const normalSwapSecureStoragePrefix = 'boltzNormalSecureData_';
  static const reverseSwapSecureStoragePrefix = 'boltzSecureData_';

  static String getNormalSwapPrefsKey(String id) => normalSwapPrefsPrefix + id;
  static String getReverseSwapPrefsKey(String id) =>
      reverseSwapPrefsPrefix + id;
  static String getNormalSwapSecureStorageKey(String id) =>
      normalSwapSecureStoragePrefix + id;
  static String getReverseSwapSecureStorageKey(String id) =>
      reverseSwapSecureStoragePrefix + id;
}
