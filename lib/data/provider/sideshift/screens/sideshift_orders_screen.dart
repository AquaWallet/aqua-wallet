import 'package:aqua/data/provider/sideshift/screens/sideshift_orders_list.dart';
import 'package:aqua/data/provider/sideshift/sideshift_order_provider.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';

class SideShiftOrdersScreen extends ConsumerWidget {
  static const routeName = '/sideShiftOrdersScreen';

  const SideShiftOrdersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return WillPopScope(
      onWillPop: () async {
        ref.read(sideshiftOrderProvider).stopAllStreams();
        logger.d('[Navigation] onWillPop in SideShiftOrdersScreen called');
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AquaAppBar(
          title: AppLocalizations.of(context)!.sideshiftOrders,
          showBackButton: true,
          showActionButton: false,
          backgroundColor: darkMode
              ? Colors.transparent
              : Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onBackground,
          elevated: true,
        ),
        body: const SideShiftOrdersList(),
      ),
    );
  }
}
