import 'package:aqua/data/models/focus_action.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Updated mock word list to test unambiguous word logic
  const mockWordList = ['apple', 'banana', 'cherry', 'catch', 'catapult'];

  ProviderContainer makeContainer() => ProviderContainer(overrides: [
        walletHintWordListProvider
            .overrideWith((_) => Future.value(mockWordList)),
      ]);

  FocusAction? latestFocusAction(ProviderContainer container) =>
      container.read(focusActionProvider);

  group('FocusActionNotifier', () {
    test('initial state is null', () {
      final container = makeContainer();
      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('does not emit action for unrecognised word', () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'unknown',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('does not emit action for empty text', () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: '',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('does not emit action for partial word matches', () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'app',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('does not emit action for ambiguous partial matches', () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      // "cat" is ambiguous because both "catch" and "catapult" start with "cat"
      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'cat',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('does not emit action for complete words when typed manually',
        () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      // Ensure the FocusActionNotifier is built by reading it first
      container.read(focusActionProvider);

      // "apple" is unambiguous - no other words start with "apple"
      // But focus should NOT move when typing manually, only when suggestion is tapped
      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'apple',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test(
        'does not emit action for complete words that are prefixes of others when typed manually',
        () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      // Ensure the FocusActionNotifier is built by reading it first
      container.read(focusActionProvider);

      // "catch" is unambiguous - no other words start with "catch"
      // But focus should NOT move when typing manually, only when suggestion is tapped
      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'catch',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('handles loading word list state', () async {
      final container = ProviderContainer(
        overrides: [
          walletHintWordListProvider.overrideWith(
            (ref) => Future.delayed(const Duration(seconds: 1), () => []),
          ),
        ],
      );

      // Should not emit action when word list is loading
      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'apple',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('handles error word list state', () async {
      final container = ProviderContainer(
        overrides: [
          walletHintWordListProvider.overrideWith(
            (ref) => Future.error('Error loading word list'),
          ),
        ],
      );

      // Should not emit action when word list has error
      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'apple',
            isSuggestion: false,
          );

      expect(latestFocusAction(container), isNull);
      container.dispose();
    });

    test('properly disposes resources', () async {
      final container = makeContainer();

      // Wait for the word list to be ready
      await container.read(walletHintWordListProvider.future);

      // Trigger some updates
      container.read(mnemonicWordInputStateProvider(0).notifier).update(
            text: 'apple',
            isSuggestion: true,
          );

      // Dispose should not throw
      expect(() => container.dispose(), returnsNormally);
    });

    group('Expected behavior', () {
      test(
          'should emit FocusAction.next when suggestion selected and next field empty',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Accept a suggestion in the first field.
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: true,
            );

        expect(latestFocusAction(container), isA<FocusActionNext>());
        container.dispose();
      });

      test('should NOT emit FocusAction.next when valid word is typed manually',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Type a valid word in the first field manually (not as suggestion).
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: false,
            );

        // Should NOT emit action when typing manually - only when suggestion is tapped
        expect(latestFocusAction(container), isNull);
        container.dispose();
      });

      test(
          'should emit FocusAction.clear when suggestion selected but next field already filled',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Prefill next field.
        container.read(mnemonicWordInputStateProvider(1).notifier).update(
              text: 'banana',
              isSuggestion: true,
            );

        // Accept suggestion in first field.
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: true,
            );

        expect(latestFocusAction(container), isA<FocusActionClear>());
        container.dispose();
      });

      test('should emit FocusAction.clear when last field is completed',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Accept suggestion in last field (index 11).
        container.read(mnemonicWordInputStateProvider(11).notifier).update(
              text: 'cherry',
              isSuggestion: true,
            );

        expect(latestFocusAction(container), isA<FocusActionClear>());
        container.dispose();
      });

      test(
          'should NOT emit action for case-insensitive word matching when typed manually',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Type a valid word with different casing manually (not as suggestion).
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'APPLE',
              isSuggestion: false,
            );

        // Should NOT emit action when typing manually - only when suggestion is tapped
        expect(latestFocusAction(container), isNull);
        container.dispose();
      });

      test('should emit FocusAction.next when valid suggestion is selected',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Select a valid suggestion (lowercase as it comes from the word list)
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'catch',
              isSuggestion: true,
            );

        expect(latestFocusAction(container), isA<FocusActionNext>());
        container.dispose();
      });

      test('should not emit action for invalid suggestion', () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // Try to select an invalid suggestion
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'invalid',
              isSuggestion: true,
            );

        expect(latestFocusAction(container), isNull);
        container.dispose();
      });

      test('should process change when text is same but isSuggestion changes',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // First, type a valid word manually (not as suggestion)
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: false,
            );

        // Clear the result
        container.read(focusActionProvider.notifier).state = null;

        // Now update the same text but as a suggestion
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: true,
            );

        // Should emit action because isSuggestion changed
        expect(latestFocusAction(container), isA<FocusActionNext>());
        container.dispose();
      });

      test('should not process change when text and isSuggestion are both same',
          () async {
        final container = makeContainer();

        // Wait for the word list to be ready
        await container.read(walletHintWordListProvider.future);

        // Ensure the FocusActionNotifier is built by reading it first
        container.read(focusActionProvider);

        // First, type a valid word as suggestion
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: true,
            );

        // Clear the result
        container.read(focusActionProvider.notifier).state = null;

        // Now update with the same text and same isSuggestion flag
        container.read(mnemonicWordInputStateProvider(0).notifier).update(
              text: 'apple',
              isSuggestion: true,
            );

        // Should not emit action because nothing changed
        expect(latestFocusAction(container), isNull);
        container.dispose();
      });
    });
  });
}
