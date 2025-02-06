class PinState {
  final String pin;
  final bool isError;
  final String? errorMessage;
  final int failedAttempts;

  PinState({
    this.pin = '',
    this.isError = false,
    this.errorMessage,
    this.failedAttempts = 0,
  });

  PinState copyWith({
    String? pin,
    bool? isError,
    String? errorMessage,
    int? failedAttempts,
  }) {
    return PinState(
      pin: pin ?? this.pin,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }
}
