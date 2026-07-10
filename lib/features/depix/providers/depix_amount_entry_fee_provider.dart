import 'dart:async';

import 'package:aqua/features/depix/models/models.dart';
import 'package:aqua/features/depix/services/jan3_api_depix.dart';
import 'package:aqua/features/depix/providers/depix_amount_formatter_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _kFeeDebounceMs = 300;

class DepixAmountEntryFeeState {
  const DepixAmountEntryFeeState({
    this.calc,
    this.isReversed = false,
    this.isLoading = false,
    this.hasError = false,
    this.conversionLine,
  });

  final EulenFeeCalculation? calc;
  final bool isReversed;
  final bool isLoading;
  final bool hasError;
  final String? conversionLine;
}

class DepixAmountEntryFeeNotifier
    extends AutoDisposeNotifier<DepixAmountEntryFeeState> {
  Timer? _debounce;
  int _requestId = 0;

  @override
  DepixAmountEntryFeeState build() {
    ref.onDispose(() => _debounce?.cancel());
    ref.watch(jan3ApiDepixProvider);
    ref.listen(
        depixAmountFormatterProvider, (_, __) => _refreshConversionLine());
    return const DepixAmountEntryFeeState();
  }

  void schedule(int cents, bool isReversed) {
    _debounce?.cancel();

    if (cents <= 0) {
      _requestId++;
      state = _buildFeeState(isReversed: isReversed);
      return;
    }

    state = _buildFeeState(isLoading: true, isReversed: isReversed);

    final requestId = ++_requestId;
    final capturedCents = cents;
    final capturedIsReversed = isReversed;

    _debounce = Timer(const Duration(milliseconds: _kFeeDebounceMs), () {
      _debounce = null;
      unawaited(_fetch(requestId, capturedCents, capturedIsReversed));
    });
  }

  Future<void> _fetch(int requestId, int cents, bool isReversed) async {
    try {
      final api = ref.read(jan3ApiDepixProvider);
      final response = isReversed
          ? await api.calculateFeeFromNet(cents)
          : await api.calculateFeeFromGross(cents);

      if (requestId != _requestId) return;

      if (response.isSuccessful && response.body != null) {
        state = _buildFeeState(calc: response.body, isReversed: isReversed);
      } else {
        state = _buildFeeState(hasError: true, isReversed: isReversed);
      }
    } catch (_) {
      if (requestId != _requestId) return;
      state = _buildFeeState(hasError: true, isReversed: isReversed);
    }
  }

  void _refreshConversionLine() {
    if (state.calc == null) return;
    state = _buildFeeState(
      calc: state.calc,
      isReversed: state.isReversed,
      isLoading: state.isLoading,
      hasError: state.hasError,
    );
  }

  DepixAmountEntryFeeState _buildFeeState({
    EulenFeeCalculation? calc,
    bool isReversed = false,
    bool isLoading = false,
    bool hasError = false,
  }) {
    final conversionLine = calc == null
        ? null
        : ref.read(depixAmountFormatterProvider).conversionLine(
              isReversed: isReversed,
              netAmountBrlCents: calc.netAmountBrlCents,
              grossAmountBrlCents: calc.grossAmountBrlCents,
            );
    return DepixAmountEntryFeeState(
      calc: calc,
      isReversed: isReversed,
      isLoading: isLoading,
      hasError: hasError,
      conversionLine: conversionLine,
    );
  }
}

final depixAmountEntryFeeProvider = NotifierProvider.autoDispose<
    DepixAmountEntryFeeNotifier, DepixAmountEntryFeeState>(
  DepixAmountEntryFeeNotifier.new,
);
