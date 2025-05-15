import 'dart:async';

/// Controller to manage error state for AquaAssetInputField
class AquaInputErrorController {
  AquaInputErrorController([
    String? error,
    this.debounceDuration = kDebounceDuration,
  ]) {
    _errorController = StreamController<String?>.broadcast();
    _visibilityController = StreamController<bool>.broadcast();
    if (error != null) {
      _lastError = error;
      _errorController.add(error);
      _isVisible = true;
      _visibilityController.add(true);
    }
  }

  static const kVisibilityDuration = Duration(seconds: 2);
  static const kDebounceDuration = Duration(milliseconds: 300);
  final Duration debounceDuration;

  late final StreamController<String?> _errorController;
  late final StreamController<bool> _visibilityController;
  String? _lastError;
  bool _isVisible = false;
  Timer? _visibilityTimer;
  Timer? _debounceTimer;

  /// Stream of error messages
  Stream<String?> get errors => _errorController.stream;

  /// Stream of error visibility state
  Stream<bool> get visibility => _visibilityController.stream;

  /// Current error value
  String? get currentError => _lastError;

  /// Current visibility state
  bool get isVisible => _isVisible;

  /// Add an error message with debouncing
  void addError(String error) {
    // Cancel any existing timers
    _visibilityTimer?.cancel();
    _debounceTimer?.cancel();

    // If the error is the same as the current error, just reset the visibility timer
    if (error == _lastError) {
      _isVisible = true;
      _visibilityController.add(true);
      _visibilityTimer = Timer(kVisibilityDuration, hideError);
      return;
    }

    // Debounce new error messages
    _debounceTimer = Timer(debounceDuration, () {
      _lastError = error;
      _errorController.add(error);
      _isVisible = true;
      _visibilityController.add(true);
      _visibilityTimer = Timer(kVisibilityDuration, hideError);
    });
  }

  /// Hide the current error but maintain its value
  void hideError() {
    _visibilityTimer?.cancel();
    _isVisible = false;
    _visibilityController.add(false);
  }

  /// Clear the current error and hide it
  void clearError() {
    _visibilityTimer?.cancel();
    _debounceTimer?.cancel();
    _lastError = null;
    _isVisible = false;
    _errorController.add(null);
    _visibilityController.add(false);
  }

  /// Dispose the controller
  void dispose() {
    _visibilityTimer?.cancel();
    _debounceTimer?.cancel();
    _errorController.close();
    _visibilityController.close();
  }
}
