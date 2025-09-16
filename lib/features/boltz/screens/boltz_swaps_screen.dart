import 'package:coin_cz/features/settings/shared/providers/prefs_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/config/config.dart';

import 'boltz_swaps_list.dart';

class BoltzSwapsScreen extends ConsumerWidget {
  static const routeName = '/boltzSwapsScreen';

  const BoltzSwapsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return Scaffold(
      extendBodyBehindAppBar: false,
      appBar: AquaAppBar(
        title: context.loc.boltzSwaps,
        showBackButton: true,
        showActionButton: false,
        backgroundColor: darkMode
            ? Colors.transparent
            : Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colors.onBackground,
      ),
      body: const BoltzSwapsList(),
    );
  }
}
