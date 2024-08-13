import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideshift/sideshift.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';

class SideShiftOrdersScreen extends ConsumerWidget {
  static const routeName = '/sideShiftOrdersScreen';

  const SideShiftOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));

    return PopScope(
      onPopInvoked: (_) async {
        ref.read(sideshiftSendProvider).stopAllStreams();
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
