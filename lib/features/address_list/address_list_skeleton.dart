import 'package:aqua/config/config.dart';
import 'package:aqua/features/settings/shared/providers/prefs_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AddressListSkeleton extends ConsumerWidget {
  const AddressListSkeleton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darkMode = ref.watch(prefsProvider.select((p) => p.isDarkMode));
    return Skeletonizer(
      effect: darkMode
          ? ShimmerEffect(
              baseColor: Theme.of(context).colors.background,
              highlightColor: Theme.of(context).colorScheme.surface,
            )
          : const ShimmerEffect(),
      child: ListView.separated(
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
        itemBuilder: (context, index) => BoxShadowCard(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.0),
          child: ListTile(
            title: Container(
              height: 20.0,
              width: 200.0,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 16.0,
              width: 100.0,
              color: Colors.white,
            ),
            trailing: Container(
              height: 24.0,
              width: 24.0,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
