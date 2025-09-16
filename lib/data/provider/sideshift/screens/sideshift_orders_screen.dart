import 'package:coin_cz/data/provider/sideshift/screens/sideshift_orders_list.dart';
import 'package:coin_cz/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:coin_cz/features/settings/shared/providers/prefs_provider.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';

class SideShiftOrdersScreen extends ConsumerWidget {
  static const routeName = '/sideShiftOrdersScreen';

  const SideShiftOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return PopScope(
      onPopInvoked: (_) async {
        ref.read(sideshiftOrderProvider).stopAllStreams();
        logger.d('[Navigation] onPopInvoked in SideShiftOrdersScreen called');
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AquaAppBar(
          title: context.loc.sideshiftOrders,
          showBackButton: true,
          showActionButton: false,
          backgroundColor: darkMode
              ? Colors.transparent
              : Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onBackground,
        ),
        body: const SideShiftOrdersList(),
      ),
    );
  }
}
