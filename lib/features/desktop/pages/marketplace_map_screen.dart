import 'package:aqua/features/desktop/pages/pages.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

class MarketplaceMapScreen extends ConsumerWidget {
  const MarketplaceMapScreen({super.key});

  static const routeName = '/marketplaceMap';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquaColors = context.aquaColors;
    return ColoredBox(
      color: aquaColors.surfaceBackground,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade700,
            ),
            child: const Center(
              child: Placeholder(),
            ),
          ),
          Positioned(
            right: 32,
            top: 32,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.aquaColors.glassSurface,
                borderRadius: BorderRadius.circular(50),
              ),
              child: AquaIcon.close(
                color: context.aquaColors.textPrimary,
                onTap: () => context.go(DesktopHomeScreen.routeName),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
