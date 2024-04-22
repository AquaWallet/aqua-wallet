import 'dart:ffi';
import 'dart:io';
import 'package:aqua/logger.dart';
import 'package:ffi/ffi.dart';
import 'dart:ffi' as ffi;
import 'ffi/generated_bindings.dart';

const rustElementsWrapperLibAndroid = "libboltz_rust.so";
const rustElementsWrapperLibMacOS = "libboltz_rust.dylib";

/// Wraps the native functions and converts specific data types in order to
/// handle C strings.

class Elements {
  static final NativeLibrary _bindings = NativeLibrary(Elements._loadLibrary());

  static DynamicLibrary _loadLibrary() {
    return Platform.isAndroid
        ? DynamicLibrary.open(rustElementsWrapperLibAndroid)
        : Platform.isMacOS
            ? DynamicLibrary.open(rustElementsWrapperLibMacOS)
            : DynamicLibrary.process();
  }

  static String extractPublicKeyFromRedeemScript(String script) {
    final ptrName = script.toNativeUtf8();

    final ptrResult =
        _bindings.extract_claim_public_key(ptrName as Pointer<Char>);

    final result = ptrResult.cast<Utf8>().toDartString();

    Elements._free(ptrResult);

    return result;
  }

  static bool validateSubmarine(
      String preImageHash,
      String claimPublicKey,
      String refundPublicKey,
      int timeoutBlockHeight,
      String lockupAddress,
      String redeemScript,
      String blindingKey) {
    final preImageHashPtr = preImageHash.toNativeUtf8();
    final claimPublicKeyPtr = claimPublicKey.toNativeUtf8();
    final refundPublicKeyPtr = refundPublicKey.toNativeUtf8();
    final lockupAddressPtr = lockupAddress.toNativeUtf8();
    final redeemScriptPtr = redeemScript.toNativeUtf8();
    final blindingKeyPtr = blindingKey.toNativeUtf8();

    final int result = _bindings.validate_submarine(
      preImageHashPtr as Pointer<Char>,
      claimPublicKeyPtr as Pointer<Char>,
      refundPublicKeyPtr as Pointer<Char>,
      timeoutBlockHeight,
      lockupAddressPtr as Pointer<Char>,
      redeemScriptPtr as Pointer<Char>,
      blindingKeyPtr as Pointer<Char>,
    );

    return result == 1;
  }

  static String constructClaimTransaction(
      String redeemScript,
      String blindingKey,
      String onchainAddress,
      String privateKey,
      String preimage,
      String tx,
      int fees) {
    final redeemScriptPtr = redeemScript.toNativeUtf8();
    final blindingKeyPtr = blindingKey.toNativeUtf8();
    final onchainAddressPtr = onchainAddress.toNativeUtf8();
    final privateKeyPtr = privateKey.toNativeUtf8();
    final preimagePtr = preimage.toNativeUtf8();
    final txPtr = tx.toNativeUtf8();

    final ptrResult = _bindings.create_and_sign_claim_transaction(
      redeemScriptPtr as Pointer<Char>,
      blindingKeyPtr as Pointer<Char>,
      onchainAddressPtr as Pointer<Char>,
      privateKeyPtr as Pointer<Char>,
      preimagePtr as Pointer<Char>,
      txPtr as Pointer<Char>,
      fees,
    );

    final result = ptrResult.cast<Utf8>().toDartString();

    Elements._free(ptrResult);

    return result;
  }

  static String constructRefundTransaction(
      String redeemScript,
      String blindingKey,
      String onchainAddress,
      String privateKey,
      String tx,
      int fees) {
    final redeemScriptPtr = redeemScript.toNativeUtf8();
    final blindingKeyPtr = blindingKey.toNativeUtf8();
    final onchainAddressPtr = onchainAddress.toNativeUtf8();
    final privateKeyPtr = privateKey.toNativeUtf8();
    final txPtr = tx.toNativeUtf8();

    final ptrResult = _bindings.create_and_sign_refund_transaction(
      redeemScriptPtr as Pointer<Char>,
      blindingKeyPtr as Pointer<Char>,
      onchainAddressPtr as Pointer<Char>,
      privateKeyPtr as Pointer<Char>,
      txPtr as Pointer<Char>,
      fees,
    );

    final result = ptrResult.cast<Utf8>().toDartString();

    Elements._free(ptrResult);

    return result;
  }

  static (String, String) getKeyPair() {
    final ptrResult = _bindings.get_key_pair();

    final result = ptrResult.cast<Utf8>().toDartString();

    final privateKey = result.split(';')[0];
    final publicKey = result.split(';')[1];

    Elements._free(ptrResult);

    return (privateKey, publicKey);
  }

  static String signMessageSchnorr(String message, String privateKey) {
    final messagePtr = message.toNativeUtf8();
    final privateKeyPtr = privateKey.toNativeUtf8();

    final ptrResult = _bindings.sign_message_schnorr(
      messagePtr as Pointer<Char>,
      privateKeyPtr as Pointer<Char>,
    );

    final result = ptrResult.cast<Utf8>().toDartString();

    Elements._free(ptrResult);

    return result;
  }

  static bool verifySignatureSchnorr(
      String signature, String message, String publicKey) {
    final signaturePtr = signature.toNativeUtf8();
    final messagePtr = message.toNativeUtf8();
    final publicKeyPtr = publicKey.toNativeUtf8();

    final result = _bindings.verify_signature_schnorr(
      signaturePtr as Pointer<Char>,
      messagePtr as Pointer<Char>,
      publicKeyPtr as Pointer<Char>,
    );

    return result == 1;
  }

  /// Releases the memory allocated to handle the given (result) value
  static void _free(Pointer<Char> value) {
    final ptr = value.cast<Int8>();
    return _bindings.rust_cstr_free(ptr as Pointer<Char>);
  }

  /// Logging
  static void setupRustLogging() {
    final callback =
        ffi.Pointer.fromFunction<ffi.Void Function(ffi.Pointer<ffi.Char>)>(
            logMessageFromRust);
    _bindings.register_log_callback(callback);
  }
}

/// Logging
typedef LogCallback = Void Function(Pointer<Int8>);
typedef LogCallbackDart = void Function(Pointer<Int8>);

void logMessageFromRust(ffi.Pointer<ffi.Char> message) {
  final String messageString = message.cast<Utf8>().toDartString();
  logger.d('[Rust] $messageString');
}
