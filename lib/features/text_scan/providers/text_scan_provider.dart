import 'dart:async';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:coin_cz/logger.dart';

final _logger = CustomLogger(FeatureFlag.textScan);

const String bech32ValidChars = 'qpzry9x8gf2tvdw0s3jn54khce6mua7l';
const String payToPublicKeyOrScriptHashValidChars =
    '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

final textScanProvider = StateNotifierProvider.autoDispose<TextScanNotifier,
    AsyncValue<List<String>>>(
  TextScanNotifier.new,
);

class TextScanNotifier extends StateNotifier<AsyncValue<List<String>>> {
  TextScanNotifier(this.ref) : super(const AsyncValue.data([]));

  final Ref ref;
  CameraController? _cameraController;
  late TextRecognizer _textRecognizer;

  CameraController? get cameraController => _cameraController;
  bool _scanAttempted = false;

  void markScanAttempted() {
    _scanAttempted = true;
  }

  bool wasScanAttempted() => _scanAttempted;

  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      state = AsyncValue.error('No cameras found', StackTrace.current);
      return;
    }

    _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    _cameraController = CameraController(
      cameras.first,
      ResolutionPreset.max,
      enableAudio: false,
    );

    try {
      await _cameraController?.initialize();
      state = const AsyncValue.data([]);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> takeSnapshotAndRecognize() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      _logger.error('Camera controller is not initialized');
      return;
    }

    state = const AsyncValue.loading();

/**
 * 
 * Addresses                                    
 * Bech32 (native SegWit) bc1q //! IS USED qpzry9x8gf2tvdw0s3jn54khce6mua7l
 * Bech32 (Taproot) bc1p
 * (P2PKH) 1... //! NO: 0 (number 0), O (letter O), I (letter I), l (letter l) // ! IS USED: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz 
 * (P2SH)  3... //! NO: 0 (number 0), O (letter O), I (letter I), l (letter l) // ! IS USED: 123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz
 * 
 * */

    /**
  * You get row string. First, we need to determine the type of address. (it starts with bc, 1, or 3 etc.)) According to type of address we use appropriate handler.
  *
  */

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final fullText = recognizedText.text;

      final lines = fullText.split('\n');
      final addresses = <String>{};
      for (String line in lines) {
        addresses.addAll(processAddress(line));
      }

      _logger.debug('Found ${addresses.length} addresses: $addresses');
      _scanAttempted = true;
      state = AsyncValue.data(addresses.toList());
    } catch (e, st) {
      _logger.error('Error processing image: $e');
      state = AsyncValue.error(e, st);
    }
  }

  List<String> processAddress(String address) {
    final addressWithoutSpace = address.replaceAll(' ', '');
    if (addressWithoutSpace.startsWith('bc')) {
      final result = '${address.substring(0, 2)}1${address.substring(3)}';
      _logger.debug('processAddress. [BC] address: $result');
      return bech32Possibilities(result);
    }

    if (addressWithoutSpace.startsWith('l') ||
        addressWithoutSpace.startsWith('i') ||
        addressWithoutSpace.startsWith('1')) {
      final result = '1${addressWithoutSpace.substring(1)}';
      _logger.debug('processAddress. [1] address: $result');
      return p2pkhAndP2shPossibilities(result);
    }

    if (addressWithoutSpace.startsWith('3')) {
      _logger.debug('processAddress. [3] address: $addressWithoutSpace');
      return p2pkhAndP2shPossibilities(addressWithoutSpace);
    }

    if (addressWithoutSpace.startsWith('VJL')) {
      _logger.debug('processAddress. [V] address: $addressWithoutSpace');
      return liquidAddressPossibilities(addressWithoutSpace);
    }

    _logger.error('invalid address: $addressWithoutSpace');
    return [];
  }

  List<String> liquidAddressPossibilities(String input) {
    const ambiguousMap = {
      'X': ['X', 'x'],
      'K': ['K', 'k'],
      'Z': ['Z', 'z'],
      'o': ['0'],
      'e': ['e', '0'],
      'i': ['l', '1'],
      'l': ['l', '1'],
      'b': ['b', '6']
    };

    return generateOcrPossibilities(
        input, ambiguousMap, payToPublicKeyOrScriptHashValidChars);
  }

  List<String> bech32Possibilities(String input) {
    const ambiguousMap = {
      'o': ['0'],
      'e': ['e', '0'],
      'i': ['l', '1'],
      'l': ['l', '1'],
      'b': ['b', '6']
    };

    return generateOcrPossibilities(input, ambiguousMap, bech32ValidChars);
  }

  List<String> p2pkhAndP2shPossibilities(String raw) {
    const ambiguousMap = {
      'e': ['e', 'o'],
      'l': ['i', '1'],
      'V': ['V', 'v'],
      'X': ['X', 'x'],
      'K': ['K', 'k'],
      // 'C': ['C', 'c'],
      // 'P': ['P', 'p'],
      // 'S': ['S', 's'],
      // 'W': ['W', 'w'],
      'Z': ['Z', 'z'],
    };

    return generateOcrPossibilities(
        raw, ambiguousMap, payToPublicKeyOrScriptHashValidChars);
  }

  List<String> generateOcrPossibilities(
      String input, Map<String, List<String>> ambiguousMap, String validChars) {
    final chars = input.split('');
    final List<int> ambiguousPositions = [];

    // look for all positions that are in ambiguousMap
    for (int i = 0; i < chars.length; i++) {
      if (ambiguousMap.containsKey(chars[i])) {
        ambiguousPositions.add(i);
      }
    }

    if (ambiguousPositions.isEmpty) {
      return [input];
    }

    final Set<String> results = {input};

    void generateVariant(int index, List<String> current) {
      if (index == ambiguousPositions.length) {
        results.add(current.join());
        return;
      }

      final pos = ambiguousPositions[index];
      final originalChar = current[pos];
      final variants = ambiguousMap[originalChar]!;

      for (final variantChar in variants) {
        current[pos] = variantChar;
        generateVariant(index + 1, current);
        current[pos] = originalChar;
      }
    }

    generateVariant(0, List.of(chars));
    return results.toList();
  }

  void resetCamera() {
    _scanAttempted = false;
    state = const AsyncValue.data([]);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _textRecognizer.close();
    super.dispose();
  }
}
