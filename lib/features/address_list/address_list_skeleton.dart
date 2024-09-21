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
              baseColor: Theme.of(context).colorScheme.background,
              highlightColor: Theme.of(context).colorScheme.surface,
            )
          : const ShimmerEffect(),
      child: ListView.separated(
        itemCount: 5,
        separatorBuilder: (context, index) => SizedBox(height: 16.h),
        padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 20.h),
        itemBuilder: (context, index) => BoxShadowCard(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          child: ListTile(
            title: Container(
              height: 20.h,
              width: 200.w,
              color: Colors.white,
            ),
            subtitle: Container(
              height: 16.h,
              width: 100.w,
              color: Colors.white,
            ),
            trailing: Container(
              height: 24.h,
              width: 24.w,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
