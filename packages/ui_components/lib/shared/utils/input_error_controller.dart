import 'dart:async';

/// A structured error with a localized label and an optional numeric amount,
/// kept separate so each part can be rendered with the correct text direction.
class AquaInputError {
  const AquaInputError({required this.label, this.amount});

  final String label;
  final String? amount;

  @override
  bool operator ==(Object other) =>
      other is AquaInputError && other.label == label && other.amount == amount;

  @override
  int get hashCode => Object.hash(label, amount);
}

/// Controller to manage error state for AquaAssetInputField
class AquaInputErrorController {
  AquaInputErrorController([
    AquaInputError? error,
    this.debounceDuration = kDebounceDuration,
  ]) {
    _errorController = StreamController<AquaInputError?>.broadcast();
    _visibilityController = StreamController<bool>.broadcast();
    if (error != null) {
      _lastError = error;
      _errorController.add(error);
      _isVisible = true;
      _visibilityController.add(true);
    }
  }

  /// Convenience factory for a simple label + optional amount, without needing
  /// to reference [AquaInputError] directly at the call site.
  factory AquaInputErrorController.fromString(String label, [String? amount]) =>
      AquaInputErrorController(AquaInputError(label: label, amount: amount));

  static const kVisibilityDuration = Duration(seconds: 2);
  static const kDebounceDuration = Duration(milliseconds: 300);
  final Duration debounceDuration;

  late final StreamController<AquaInputError?> _errorController;
  late final StreamController<bool> _visibilityController;
  AquaInputError? _lastError;
  bool _isVisible = false;
  Timer? _visibilityTimer;
  Timer? _debounceTimer;

  /// Stream of error messages
  Stream<AquaInputError?> get errors => _errorController.stream;

  /// Stream of error visibility state
  Stream<bool> get visibility => _visibilityController.stream;

  /// Current error value
  AquaInputError? get currentError => _lastError;

  /// Current visibility state
  bool get isVisible => _isVisible;

  /// Convenience method — wraps plain strings into an [AquaInputError] and adds it.
  void addStringError(String label, [String? amount]) {
    addError(AquaInputError(label: label, amount: amount));
  }

  /// Add a structured error with debouncing
  void addError(AquaInputError error) {
    // Cancel any existing timers
    _visibilityTimer?.cancel();
    _debounceTimer?.cancel();

    // If the error is the same as the current error, just keep it visible
    if (error == _lastError) {
      _isVisible = true;
      _visibilityController.add(true);
      return;
    }

    // Debounce new error messages
    _debounceTimer = Timer(debounceDuration, () {
      _lastError = error;
      _errorController.add(error);
      _isVisible = true;
      _visibilityController.add(true);
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
