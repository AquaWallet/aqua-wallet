import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class WalletRestoreInputScreen extends HookConsumerWidget {
  static const routeName = '/walletRestoreInput';

  const WalletRestoreInputScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasError = useState(false);

    ref.listen(
      walletRestoreProvider,
      (_, asyncValue) {
        hasError.value = false;
        asyncValue.maybeWhen(
          loading: () => showGeneralDialog(
            context: context,
            pageBuilder: (_, __, ___) => const WalletProcessingAnimation(
              type: WalletProcessType.restore,
            ),
          ),
          error: (_, __) {
            hasError.value = true;
            Navigator.of(context).popUntil((route) => route is! RawDialogRoute);
          },
          orElse: () {},
        );
      },
    );

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        iconBackgroundColor: Theme.of(context).colorScheme.background,
        iconForegroundColor: Theme.of(context).colorScheme.onBackground,
        onBackPressed: () {
          ref.read(systemOverlayColorProvider(context)).aqua();
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: ref.watch(walletHintWordListProvider).when(
                  data: (_) => WalletRestoreInputContent(error: hasError),
                  loading: () => Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  error: (_, __) => GenericErrorWidget(
                    buttonAction: () =>
                        ref.invalidate(walletInputHintsProvider),
                  ),
                ) ??
            Container(),
      ),
    );
  }
}
