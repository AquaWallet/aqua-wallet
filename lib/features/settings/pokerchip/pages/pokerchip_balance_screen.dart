import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/features/settings/pokerchip/pokerchip.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class PokerchipBalanceScreen extends HookConsumerWidget {
  const PokerchipBalanceScreen({super.key});

  static const routeName = '/pokerchipBalanceScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final address = ModalRoute.of(context)?.settings.arguments as String;
    final pokerchipBalance = ref.watch(pokerchipBalanceProvider(address));
    final error = pokerchipBalance.hasError;

    useEffect(() {
      if (error) {
        Future.microtask(
            () => context.showErrorSnackbar(context.loc.pokerChipBalanceError));
      }
      return null;
    }, [error]);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.pokerchipScreenTitle,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Column(
            children: [
              //ANCHOR - Pokerchip Info
              pokerchipBalance.when(
                data: (balance) => PokerchipBalanceCard(data: balance),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              //ANCHOR: Explore button
              AquaElevatedButton(
                onPressed: pokerchipBalance.whenOrNull(
                  data: (value) => () =>
                      ref.read(urlLauncherProvider).open(value.explorerLink),
                ),
                child: Text(
                  context.loc.pokerChipBalanceExplorerButton,
                ),
              ),
              SizedBox(height: 36.h),
            ],
          ),
        ),
      ),
    );
  }
}
