import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:mocktail/mocktail.dart';

class MockSendAssetFeeOptionsNotifier extends AutoDisposeFamilyAsyncNotifier<
    List<SendAssetFeeOptionModel>,
    SendAssetArguments> with Mock implements SendAssetFeeOptionsNotifier {
  MockSendAssetFeeOptionsNotifier(this.feeOptions);

  final List<SendAssetFeeOptionModel> feeOptions;
}
