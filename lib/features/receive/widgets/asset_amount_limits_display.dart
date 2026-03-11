import 'package:aqua/features/settings/manage_assets/models/assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:ui_components/ui_components.dart';

class AssetAmountLimitsDisplay extends HookConsumerWidget {
  const AssetAmountLimitsDisplay({
    super.key,
    required this.asset,
    required this.minLimit,
    required this.maxLimit,
  });

  final Asset asset;
  final String? minLimit;
  final String? maxLimit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Skeletonizer(
      enabled: minLimit == null || maxLimit == null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AquaText.body2Medium(
            text: context.loc.minValueVariant(minLimit ?? ''),
            color: context.aquaColors.textSecondary,
          ),
          AquaText.body2Medium(
            text: context.loc.maxValueVariant(maxLimit ?? ''),
            color: context.aquaColors.textSecondary,
          ),
        ],
      ),
    );
  }
}
