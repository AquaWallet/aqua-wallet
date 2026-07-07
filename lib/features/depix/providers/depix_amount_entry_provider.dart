import 'package:aqua/data/provider/formatter_provider.dart';
import 'package:aqua/features/depix/providers/depix_amount_entry_fee_provider.dart';
import 'package:aqua/features/depix/providers/depix_deposit_provider.dart';
import 'package:aqua/features/depix/providers/depix_amount_formatter_provider.dart';
import 'package:aqua/features/send/send.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:ui_components/ui_components.dart';

class DepixAmountEntryState {
  const DepixAmountEntryState({
    this.fieldText = '',
    this.isReversed = false,
    this.inputAmount = 0.0,
    this.primaryLine = '',
    this.canContinue = false,
    this.conversionLine,
    this.isLoading = false,
    this.hasError = false,
  });

  final String fieldText;
  final bool isReversed;
  final double inputAmount;
  final String primaryLine;
  final bool canContinue;
  final String? conversionLine;
  final bool isLoading;
  final bool hasError;
}

class DepixAmountEntryNotifier
    extends AutoDisposeNotifier<DepixAmountEntryState> {
  @override
  DepixAmountEntryState build() {
    ref.listen(depixAmountEntryFeeProvider, (_, __) => _recompute());
    ref.listen(depixAmountFormatterProvider, (_, __) => _recompute());
    return _buildViewState(fieldText: '', isReversed: false, inputAmount: 0.0);
  }

  void addKey(MnemonicKeyboardKey key) {
    final newText = _applyKey(state.fieldText, key);
    if (newText == state.fieldText) return;
    final amount = _parseAmount(newText);
    state = _buildViewState(
      fieldText: newText,
      isReversed: state.isReversed,
      inputAmount: amount,
    );
    ref.read(depixAmountEntryFeeProvider.notifier).schedule(
          (amount * 100).round(),
          state.isReversed,
        );
  }

  String _applyKey(String current, MnemonicKeyboardKey key) {
    final decimalSeparator = depixBrlFormat.format.decimalSeparator;
    final precision = depixBrlFormat.format.decimalPlaces;

    if (key.isBackspaceKey) {
      return current.isNotEmpty
          ? current.substring(0, current.length - 1)
          : current;
    }
    if (key is MnemonicKeyboardLetterKey) {
      if (key.text == decimalSeparator) {
        if (!current.contains(decimalSeparator)) {
          return normalizeDecimalStart('$current$decimalSeparator');
        }
        return current;
      }
      if (current == '0' && key.text == '0') return current;
      final newText = current + key.text;
      if (newText.contains(decimalSeparator)) {
        final decimalIndex = newText.lastIndexOf(decimalSeparator);
        final decimalPart = newText.substring(decimalIndex + 1);
        if (decimalPart.length > precision) return current;
      }
      return newText;
    }
    return current;
  }

  double _parseAmount(String text) {
    final raw = text.trim();
    if (raw.isEmpty) return 0.0;
    final formatter = ref.read(formatterProvider);
    final cleaned = formatter.cleanAmountString(raw, depixBrlFormat.format);
    return double.tryParse(cleaned) ?? 0.0;
  }

  void submitDeposit() {
    final calc = ref.read(depixAmountEntryFeeProvider).calc;
    if (calc == null) return;
    ref.read(depixDepositProvider.notifier).submitWithFee(
          calc.grossAmountBrlCents,
          calc.extraChargesBrlCents,
        );
  }

  void toggleReversed() {
    final calc = ref.read(depixAmountEntryFeeProvider).calc;
    final swappedText = calc == null
        ? ''
        : ref
            .read(depixAmountFormatterProvider)
            .swapFieldText(calc, state.isReversed);
    final newReversed = !state.isReversed;
    final amount = _parseAmount(swappedText);
    state = _buildViewState(
      fieldText: swappedText,
      isReversed: newReversed,
      inputAmount: amount,
    );
    ref.read(depixAmountEntryFeeProvider.notifier).schedule(
          (amount * 100).round(),
          newReversed,
        );
  }

  void _recompute() {
    state = _buildViewState(
      fieldText: state.fieldText,
      isReversed: state.isReversed,
      inputAmount: state.inputAmount,
    );
  }

  DepixAmountEntryState _buildViewState({
    required String fieldText,
    required bool isReversed,
    required double inputAmount,
  }) {
    final fee = ref.read(depixAmountEntryFeeProvider);
    final formatter = ref.read(depixAmountFormatterProvider);
    return DepixAmountEntryState(
      fieldText: fieldText,
      isReversed: isReversed,
      inputAmount: inputAmount,
      primaryLine: formatter.primaryLine(
        isReversed: isReversed,
        rawFieldText: fieldText,
      ),
      canContinue: inputAmount > 0 &&
          !fee.isLoading &&
          fee.calc != null &&
          fee.calc!.netAmountBrlCents > 0,
      conversionLine: fee.conversionLine,
      isLoading: fee.isLoading,
      hasError: fee.hasError,
    );
  }
}

final depixAmountEntryProvider = NotifierProvider.autoDispose<
    DepixAmountEntryNotifier, DepixAmountEntryState>(
  DepixAmountEntryNotifier.new,
);
