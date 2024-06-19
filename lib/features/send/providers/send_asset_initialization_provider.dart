import 'package:aqua/features/lightning/providers/lnurl_provider.dart';
import 'package:aqua/features/send/models/models.dart';
import 'package:aqua/features/send/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';

class SendAssetInitializationNotifier extends StateNotifier<AsyncValue<void>> {
  SendAssetInitializationNotifier(this.ref, this.arguments)
      : super(const AsyncValue.loading());

  final Ref ref;
  final SendAssetArguments arguments;

  Future<void> initialize() async {
    try {
      ref.read(sendAssetProvider.notifier).state = arguments.asset;
      ref.read(sendAddressProvider.notifier).state = arguments.input;
      await ref
          .read(userEnteredAmountProvider.notifier)
          .updateAmount(arguments.userEnteredAmount);
      ref.read(lnurlParseResultProvider.notifier).state =
          arguments.lnurlParseResult;
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final initializationProvider = StateNotifierProvider.autoDispose.family<
    SendAssetInitializationNotifier, AsyncValue<void>, SendAssetArguments>(
  (ref, arguments) => SendAssetInitializationNotifier(ref, arguments),
);
