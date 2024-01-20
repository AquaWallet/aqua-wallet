import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'ffi/generated_bindings.dart';

const rustElementsWrapperLibAndroid = "librust_elements_wrapper.so";
const rustElementsWrapperLibMacOS = "librust_elements_wrapper.dylib";

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

    // Cast the result pointer to a Dart string
    final result = ptrResult.cast<Utf8>().toDartString();

    // Clone the given result, so that the original string can be freed
    final resultCopy = "" + result;

    // Free the native value
    Elements._free(result);

    return resultCopy;
  }

  static String constructRedeemScript(String preImageHash,
      String claimPublicKey, String refundPublicKey, int timeoutBlockHeight) {
    final preImageHashPtr = preImageHash.toNativeUtf8();
    final claimPublicKeyPtr = claimPublicKey.toNativeUtf8();
    final refundPublicKeyPtr = refundPublicKey.toNativeUtf8();

    final ptrResult = _bindings.reconstruct_swap_script(
        preImageHashPtr as Pointer<Char>,
        claimPublicKeyPtr as Pointer<Char>,
        refundPublicKeyPtr as Pointer<Char>,
        timeoutBlockHeight);

    // Cast the result pointer to a Dart string
    final result = ptrResult.cast<Utf8>().toDartString();

    // Clone the given result, so that the original string can be freed
    final resultCopy = "" + result;

    // Free the native value
    Elements._free(result);

    return resultCopy;
  }

  /// Releases the memory allocated to handle the given (result) value
  static void _free(String value) {
    final ptr = value.toNativeUtf8().cast<Int8>();
    return _bindings.rust_cstr_free(ptr as Pointer<Char>);
  }
}
