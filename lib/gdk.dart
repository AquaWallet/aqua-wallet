import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:aqua/ffi/generated_bindings.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/logger.dart';
import 'package:async/async.dart';
import 'package:ffi/ffi.dart';
import 'package:nanoid/async.dart';

class AuthHandler {
  String id;
  Pointer<GA_auth_handler> authHandler;
  late DateTime createdAt;

  AuthHandler({
    required this.id,
    required this.authHandler,
  }) {
    createdAt = DateTime.now();
  }

  AuthHandler copyWith({
    String? id,
    Pointer<GA_auth_handler>? authHandler,
  }) {
    return AuthHandler(
      id: id ?? this.id,
      authHandler: authHandler ?? this.authHandler,
    );
  }

  @override
  String toString() =>
      'AuthHandler(id: $id, authHandler: $authHandler, createdAt: $createdAt)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AuthHandler &&
        other.id == id &&
        other.authHandler == authHandler &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => id.hashCode ^ authHandler.hashCode ^ createdAt.hashCode;
}

typedef DartPostCObject = Pointer Function(
    Pointer<NativeFunction<Int8 Function(Int64, Pointer<Dart_CObject>)>>);

class LibGdkBindings {
  static LibGdkBindings? _instance;

  String get _libName {
    if (Platform.isLinux || Platform.isAndroid) return 'libgreen_gdk_java.so';
    if (Platform.isMacOS) return 'libgreen_gdk.dylib';
    // if (Platform.isWindows) return 'libgreen_gdk.dll';
    throw Exception('${Platform.operatingSystem} is not supported');
  }

  String get _libHelperName {
    if (Platform.isLinux || Platform.isAndroid) return 'libdart_helper.so';
    if (Platform.isMacOS) return 'libdart_helper.dylib';
    // if (Platform.isWindows) return 'libgreen_gdk.dll';
    throw Exception('${Platform.operatingSystem} is not supported');
  }

  late final DynamicLibrary greenGdkLib;
  late final DynamicLibrary dartHelperLib;

  factory LibGdkBindings([String dllPath = '', String helperPath = '']) =>
      _instance ??= LibGdkBindings._(dllPath, helperPath);

  LibGdkBindings._([String dllPath = '', String helperPath = '']) {
    if (Platform.isIOS) {
      greenGdkLib = DynamicLibrary.process();
      dartHelperLib = DynamicLibrary.process();
    } else {
      greenGdkLib = DynamicLibrary.open(dllPath.isEmpty ? _libName : dllPath);
      dartHelperLib =
          DynamicLibrary.open(helperPath.isEmpty ? _libHelperName : helperPath);
    }
  }

  NativeLibrary get lib => NativeLibrary(greenGdkLib);
  NativeLibrary get hLib => NativeLibrary(dartHelperLib);

  void closeDll() {
    _dlCloseFunc(greenGdkLib.handle);
    _dlCloseFunc(dartHelperLib.handle);
    _instance = null;
  }

  int Function(Pointer<Void>) get _dlCloseFunc {
    final funcName = Platform.isWindows ? 'FreeLibrary' : 'dlclose';
    return _stdlib
        .lookup<NativeFunction<Int32 Function(Pointer<Void>)>>(funcName)
        .asFunction();
  }

  DynamicLibrary get _stdlib => Platform.isWindows
      ? DynamicLibrary.open('kernel32.dll')
      : DynamicLibrary.process();
}

class LibGdk {
  LibGdk._internal();

  static final _libGdk = LibGdk._internal();

  late LibGdkBindings bindings;
  final arena = Arena();

  factory LibGdk([String dllPath = '', String helperPath = '']) {
    _libGdk.bindings = LibGdkBindings(dllPath, helperPath);
    return _libGdk;
  }

  final _authHandlers = <String, AuthHandler>{};

  late Pointer<NativeFunction<Void Function(Pointer<Void>, Pointer<GA_json>)>>
      _notificationHandler;

  Future<String> saveAuthHandler(Pointer<GA_auth_handler> authHandler) async {
    final id = await nanoid(21);
    final newAuthHandler = AuthHandler(id: id, authHandler: authHandler);
    _authHandlers[id] = newAuthHandler;

    logger.d('Handler created: $id');

    return id;
  }

  void freeOldAuthHandler() {
    for (var key in _authHandlers.keys) {
      if (_authHandlers[key]!.createdAt.difference(DateTime.now()) >
          const Duration(minutes: 5)) {
        cleanAuthHandler(key);
      }
    }
  }

  void cleanAuthHandler(String? id) {
    if (id == null) {
      logger.w('Auth handler id is empty');
      return;
    }

    if (_authHandlers.containsKey(id)) {
      _destroyAuthHandler(_authHandlers[id]!.authHandler);
      _authHandlers.remove(id);

      logger.d('Handler deleted: $id');
    }
  }

  Result<Pointer<GA_json>> toJson(String x) {
    final pointer = arena<Pointer<GA_json>>();
    final result = bindings.lib.GA_convert_string_to_json(
        x.toNativeUtf8(allocator: arena).cast(), pointer);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return Result.value(pointer.value);
  }

  Result<String> fromJson(Pointer<GA_json> json) {
    final output = arena<Pointer<Char>>();
    final result = bindings.lib.GA_convert_json_to_string(json, output);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }
    return Result.value(output.value.cast<Utf8>().toDartString());
  }

  Result<bool> _checkResult({required int result}) {
    if (result != 0) {
      return Result.error('Result: $result', StackTrace.current);
    }

    return Result.value(true);
  }

  Future<Result<String>> getNetworks() async {
    final output = arena<Pointer<GA_json>>();
    final result = bindings.lib.GA_get_networks(output);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final data = fromJson(output.value);
    if (data.isError) {
      return Result.error(data.asError!.error, data.asError!.stackTrace);
    }

    return Result.value(data.asValue!.value);
  }

  Pointer<Void> initContext(int nativePort) {
    final createContext = bindings.dartHelperLib.lookupFunction<
        Pointer<Void> Function(Int64),
        Pointer<Void> Function(int)>('create_context');

    _notificationHandler = bindings.dartHelperLib
        .lookup<NativeFunction<Void Function(Pointer<Void>, Pointer<GA_json>)>>(
            'notification_handler');

    return createContext(nativePort);
  }

  Future<void> initGdk(GdkConfig config) async {
    final setPostObjectPtr = bindings.dartHelperLib
        .lookupFunction<DartPostCObject, DartPostCObject>(
            'set_post_object_ptr');
    setPostObjectPtr(NativeApi.postCObject);

    final json = toJson(config.toJsonString());
    if (json.isError) {
      logger.e(json.asError!.error);
      logger.e(json.asError!.stackTrace);
      throw json.asError!.error;
    }

    final result = bindings.lib.GA_init(json.asValue!.value);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      logger.e(checkResult.asError!.error);
      logger.e(checkResult.asError!.stackTrace);
      throw checkResult.asError!.error;
    }

    logger.d('Gdk initialized');
    return;
  }

  Future<Result<bool>> validateMnemonic(List<String> mnemonic) async {
    final mnemonicStr = mnemonic.join(' ');
    final valid = arena<Uint32>();
    final result = bindings.lib.GA_validate_mnemonic(
        mnemonicStr.toNativeUtf8(allocator: arena).cast(), valid);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    if (valid.value == 1) {
      return Result.value(true);
    }

    return Result.value(false);
  }

  Result<Pointer<GA_session>> createSession() {
    final pointer = arena<Pointer<GA_session>>();
    var result = bindings.lib.GA_create_session(pointer);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }
    return Result.value(pointer.value);
  }

  void destroySession({required Pointer<GA_session> session}) {
    final result = bindings.lib.GA_destroy_session(session);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      logger.e(checkResult.asError!.error);
      logger.e(checkResult.asError!.stackTrace);
    }
  }

  Future<Result<bool>> connect({
    required Pointer<GA_session> session,
    required GdkConnectionParams connectionParams,
    required Pointer<Void> context,
  }) async {
    var result = bindings.lib
        .GA_set_notification_handler(session, _notificationHandler, context);
    var checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return checkResult;
    }

    logger.d(connectionParams.toJsonString());
    final pointerJson = toJson(connectionParams.toJsonString());

    if (pointerJson.isError) {
      return Result.error(
          pointerJson.asError!.error, pointerJson.asError!.stackTrace);
    }

    result = bindings.lib.GA_connect(session, pointerJson.asValue!.value);
    checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return checkResult;
    }

    return Result.value(true);
  }

  void _destroyAuthHandler(Pointer<GA_auth_handler> authHandler) {
    final result = bindings.lib.GA_destroy_auth_handler(authHandler);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      logger.e(checkResult.asError!.error);
      logger.e(checkResult.asError!.stackTrace);
    }
  }

  void _destroyJson(Pointer<GA_json> json) {
    final result = bindings.lib.GA_destroy_json(json);
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      logger.e(checkResult.asError!.error);
      logger.e(checkResult.asError!.stackTrace);
    }
  }

  Future<Result<GdkAuthHandlerStatus>> _createAuthHandler(
      Pointer<GA_auth_handler> authHandler) async {
    final id = await saveAuthHandler(authHandler);

    return _authHandlerGetStatus(id);
  }

  Future<Result<GdkAuthHandlerStatus>> _authHandlerGetStatus(
    String id,
  ) async {
    if (!_authHandlers.containsKey(id)) {
      return Result.error('Auth handler not exist', StackTrace.current);
    }

    final authHandler = _authHandlers[id]!.authHandler;

    final output = arena<Pointer<GA_json>>();
    var result = bindings.lib.GA_auth_handler_get_status(authHandler, output);
    logger.d('auth_handler_get_status result: $result');
    if (result != 0) {
      cleanAuthHandler(id);
    }
    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(output.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }
    _destroyJson(output.value);

    logger.d('auth handler status: ${jsonStr.asValue!.value}');

    var status = GdkAuthHandlerStatus.fromJson(
        jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>);

    if (status.status == GdkAuthHandlerStatusEnum.error) {
      return Result.value(status.copyWith(authHandlerId: id));
    }

    return Result.value(status.copyWith(authHandlerId: id));
  }

  Future<Result<GdkAuthHandlerStatus>> authHandlerCall(String? id) async {
    if (id == null) {
      return Result.error('Id is null', StackTrace.current);
    }

    if (!_authHandlers.containsKey(id)) {
      return Result.error(
          'Missing id in auth handler list', StackTrace.current);
    }

    final authHandler = _authHandlers[id]!.authHandler;

    var result = bindings.lib.GA_auth_handler_call(authHandler);
    if (result < 0) {
      logger.e('auth_handler_call result: $result');
    } else {
      logger.d('auth_handler_call result: $result');
    }

    if (result != 0) {
      cleanAuthHandler(id);
    }

    var checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final output = arena<Pointer<GA_json>>();
    result = bindings.lib.GA_auth_handler_get_status(authHandler, output);
    logger.d('auth_handler_get_status result: $result');
    if (result != 0) {
      cleanAuthHandler(id);
    }

    checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(output.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }

    logger.d('output: ${jsonStr.asValue!.value}');

    final status = GdkAuthHandlerStatus.fromJson(
        jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>);
    return Result.value(status.copyWith(authHandlerId: id));
  }

  Future<Result<GdkAuthHandlerStatus>> loginUser({
    required Pointer<GA_session> session,
    GdkHwDevice? hwDevice,
    required GdkLoginCredentials credentials,
    String password = '',
  }) async {
    hwDevice ??= const GdkHwDevice();

    final json = toJson(hwDevice.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final credentialsJson = toJson(credentials.toJsonString());
    if (credentialsJson.isError) {
      return Result.error(
          credentialsJson.asError!.error, credentialsJson.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    var result = bindings.lib.GA_login_user(
      session,
      json.asValue!.value,
      credentialsJson.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> registerUser({
    required Pointer<GA_session> session,
    GdkHwDevice? hwDevice,
    required GdkLoginCredentials credentials,
  }) async {
    hwDevice ??= const GdkHwDevice();

    final json = toJson(hwDevice.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    logger.d('Register credentials: ${credentials.toJsonString()}');
    final credentialsJson = toJson(credentials.toJsonString());
    if (credentialsJson.isError) {
      return Result.error(
          credentialsJson.asError!.error, credentialsJson.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_register_user(
      session,
      json.asValue!.value,
      credentialsJson.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  /// creating subaccount isn't needed now
  ///
  /// Example how to call function from gdk_backend
  /// ```dart
  /// result = await gdk.createSubaccount(
  ///   // default values inside GdkCreateSubaccount
  ///  details: const GdkCreateSubaccount(),
  /// );
  ///
  /// gdkBackendResult = await _resolveGdkFunctionStatus(
  ///   result,
  ///   GdkBackendResultEnum.createSubaccount,
  /// );
  ///
  /// logger.d(gdkBackendResult);
  ///
  /// send<GdkBackendResult>(GdkEvent.backendResult, gdkBackendResult);
  /// ```
  ///
  Future<Result<GdkAuthHandlerStatus>> createSubaccount({
    required Pointer<GA_session> session,
    required GdkSubaccount details,
  }) async {
    logger.d(details.toJsonString());

    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_create_subaccount(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getTransactions({
    required Pointer<GA_session> session,
    required GdkGetTransactionsDetails details,
  }) async {
    logger.d(details.toJsonString());

    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_get_transactions(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getBalance({
    required Pointer<GA_session> session,
    required GdkGetBalance details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_get_balance(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getSubaccounts({
    required Pointer<GA_session> session,
    required GdkGetSubaccountsDetails details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_get_subaccounts(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getSubaccount({
    required Pointer<GA_session> session,
    required int subaccount,
  }) async {
    final authHandler = arena<Pointer<GA_auth_handler>>();

    final result = bindings.lib.GA_get_subaccount(
      session,
      subaccount,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getReceiveAddress({
    required Pointer<GA_session> session,
    required GdkReceiveAddressDetails details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_get_receive_address(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getPreviousAddresses({
    required Pointer<GA_session> session,
    required GdkPreviousAddressesDetails details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_get_previous_addresses(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> signPsbt({
    required Pointer<GA_session> session,
    required GdkSignPsbtDetails details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_psbt_sign(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> getDetailsPsbt({
    required Pointer<GA_session> session,
    required GdkPsbtGetDetails details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_psbt_get_details(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<Map<String, dynamic>>> getSettings({
    required Pointer<GA_session> session,
  }) async {
    final output = arena<Pointer<GA_json>>();
    final result = bindings.lib.GA_get_settings(
      session,
      output,
    );

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(output.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }

    _destroyJson(output.value);

    return Result.value(
        jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>);
  }

  Future<Result<GdkAuthHandlerStatus>> changeSettings({
    required Pointer<GA_session> session,
    required GdkSettingsEvent settings,
  }) async {
    final json = toJson(settings.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_change_settings(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<void>> refreshAssets({
    required Pointer<GA_session> session,
    required GdkAssetsParameters params,
  }) async {
    // params to json
    final json = toJson(params.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    // call c function and map result to j
    final result = bindings.lib.GA_refresh_assets(
      session,
      json.asValue!.value,
    );

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return Result<void>.value(null);
  }

  // This is a bit of a hack to validate btc and lbtc addresses.
  // We create a `GdkNewTransaction` with the address to validate and if it's invalid for the network then this will return false.
  Future<Result<GdkAuthHandlerStatus>> isValidAddress({
    required Pointer<GA_session> session,
    required String address,
    required int subaccount,
  }) async {
    if (address.isEmpty) {
      return Result.error('Address is empty', StackTrace.current);
    }
    final addressee = GdkNewTransaction(
        addressees: [GdkAddressee(address: address, satoshi: 1000)],
        subaccount: subaccount);

    logger.d(addressee.toJsonString());

    final json = toJson(addressee.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    return await createTransaction(session: session, transaction: addressee);
  }

  Future<Result<String>> generateMnemonic12() async {
    final pointer = arena<Pointer<Char>>();
    final result = bindings.lib.GA_generate_mnemonic_12(pointer);

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final mnemonic = pointer.value.cast<Utf8>().toDartString();
    bindings.lib.GA_destroy_string(pointer.value);

    return Result.value(mnemonic);
  }

  Future<Result<Map<String, GdkAssetInformation>>> getAssets({
    required Pointer<GA_session> session,
    required GdkGetAssetsParameters params,
  }) async {
    final json = toJson(params.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final output = arena<Pointer<GA_json>>();
    final result =
        bindings.lib.GA_get_assets(session, json.asValue!.value, output);

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(output.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }

    _destroyJson(output.value);

    // Check for errors in json
    final outputMap = <String, GdkAssetInformation>{};
    final jsonMap = jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>;
    // ignore: unnecessary_null_comparison
    if (jsonMap == null) {
      logger.e("[ASSETS] gdk: Decoded JSON is not a valid map.");
      return Result.error("Decoded JSON is not a valid map.");
    }
    if (jsonMap.containsKey('error')) {
      logger.w("[ASSETS] gdk: ${jsonMap['error']}");
      //_getThreadErrorDetails(); // this call is re-entrant is return never hits - not sure why - commenting for now - this the only place it's used
      return Result.error(jsonMap['error']);
    }
    if (jsonMap['assets'] is! Map<String, dynamic> ||
        jsonMap['icons'] is! Map<String, dynamic>) {
      logger.e(
          "[ASSETS] gdk: Invalid assets or icons data structure in jsonMap.");
      return Result.error("Invalid assets or icons data structure in jsonMap.");
    }

    // Map json to Map<String, GdkAssetInformation>
    final assetsMap = jsonMap['assets'] as Map<String, dynamic>;

    for (var key in assetsMap.keys) {
      final asset = assetsMap[key] as Map<String, dynamic>;
      outputMap[key] = GdkAssetInformation.fromJson(asset);
    }

    return Result.value(outputMap);
  }

  Future<Result<Map<String, dynamic>>> getFeeEstimates({
    required Pointer<GA_session> session,
  }) async {
    final output = arena<Pointer<GA_json>>();
    final result = bindings.lib.GA_get_fee_estimates(
      session,
      output,
    );

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(output.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }

    _destroyJson(output.value);

    return Result.value(
        jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>);
  }

  Future<Result<GdkAuthHandlerStatus>> createTransaction({
    required Pointer<GA_session> session,
    required GdkNewTransaction transaction,
    bool rbfEnabled = true,
    bool isRbfTx = false,
    Map<String, List<GdkUnspentOutputs>>? utxos,
  }) async {
    Map<String, List<GdkUnspentOutputs>> transactionUtxos;

    if (utxos == null) {
      final details = GdkGetUnspentOutputs(subaccount: transaction.subaccount);
      final utxoResult =
          await getUnspentOutputs(session: session, details: details);
      transactionUtxos =
          utxoResult.asValue!.value.result!.unspentOutputs!.unsentOutputs!;
    } else {
      transactionUtxos = utxos;
    }

    Map<String, List<GdkUnspentOutputs>> utxosWithSequence = {};
    transactionUtxos.forEach((key, value) {
      utxosWithSequence[key] = value.map((utxo) {
        // disable RBF if not enabled
        return utxo.copyWith(sequence: rbfEnabled ? utxo.sequence : 0xFFFFFFFF);
      }).toList();
    });

    logger.d('[GDK] create transaction: ${transaction.toJsonString()}');
    final transactionPayload = transaction.copyWith(
        utxos: isRbfTx || rbfEnabled ? transactionUtxos : utxosWithSequence);

    final json = toJson(transactionPayload.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_create_transaction(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> blindTransaction({
    required Pointer<GA_session> session,
    required GdkNewTransactionReply transactionReply,
  }) async {
    final json = toJson(transactionReply.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_blind_transaction(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> signTransaction({
    required Pointer<GA_session> session,
    required GdkNewTransactionReply transactionReply,
  }) async {
    final json = toJson(transactionReply.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_sign_transaction(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<GdkAuthHandlerStatus>> sendTransaction(
      {required Pointer<GA_session> session,
      required GdkNewTransactionReply transactionReply}) async {
    final json = toJson(transactionReply.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib.GA_send_transaction(
      session,
      json.asValue!.value,
      authHandler,
    );

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<Map<String, dynamic>>> convertAmount({
    required Pointer<GA_session> session,
    required GdkConvertData valueDetails,
  }) async {
    final json = toJson(valueDetails.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final output = arena<Pointer<GA_json>>();
    final result =
        bindings.lib.GA_convert_amount(session, json.asValue!.value, output);

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(output.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }

    _destroyJson(output.value);

    return Result.value(
        jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>);
  }

  Future<Result<GdkAuthHandlerStatus>> getUnspentOutputs({
    required Pointer<GA_session> session,
    required GdkGetUnspentOutputs details,
  }) async {
    final json = toJson(details.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    final authHandler = arena<Pointer<GA_auth_handler>>();
    final result = bindings.lib
        .GA_get_unspent_outputs(session, json.asValue!.value, authHandler);

    if (result != 0) {
      _destroyAuthHandler(authHandler.value);
    }

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return _createAuthHandler(authHandler.value);
  }

  Future<Result<bool>> registerNetwork({
    required String name,
    required GdkNetwork networkDetails,
  }) async {
    final json = toJson(networkDetails.toJsonString());
    if (json.isError) {
      return Result.error(json.asError!.error, json.asError!.stackTrace);
    }

    Pointer<Char> networkName = name.toNativeUtf8(allocator: arena).cast();

    final result = bindings.lib.GA_register_network(
      networkName,
      json.asValue!.value,
    );

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return Result.value(true);
  }

  Future<Result<void>> setTransactionMemo({
    required Pointer<GA_session> session,
    required String txhash,
    required String memo,
  }) async {
    final Pointer<Char> txhashHex =
        txhash.toNativeUtf8(allocator: arena).cast();
    final Pointer<Char> memoPointer =
        memo.toNativeUtf8(allocator: arena).cast();

    final result = bindings.lib
        .GA_set_transaction_memo(session, txhashHex, memoPointer, 0);

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    return Result<void>.value(null);
  }

  Future<Result<Map<String, dynamic>>> getAvailableCurrencies({
    required Pointer<GA_session> session,
  }) async {
    final currencies = arena<Pointer<GA_json>>();
    final result =
        bindings.lib.GA_get_available_currencies(session, currencies);

    final checkResult = _checkResult(result: result);
    if (checkResult.isError) {
      return Result.error(
          checkResult.asError!.error, checkResult.asError!.stackTrace);
    }

    final jsonStr = fromJson(currencies.value);
    if (jsonStr.isError) {
      return Result.error(jsonStr.asError!.error, jsonStr.asError!.stackTrace);
    }

    _destroyJson(currencies.value);

    return Result.value(
        jsonDecode(jsonStr.asValue!.value) as Map<String, dynamic>);
  }
}
