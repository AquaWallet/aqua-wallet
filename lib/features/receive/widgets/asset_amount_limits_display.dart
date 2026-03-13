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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaText.body2Medium(
                text: context.loc.minLabel,
                color: context.aquaColors.textSecondary,
              ),
              const SizedBox(width: 4),
              AquaText.body2Medium(
                text: minLimit ?? '',
                color: context.aquaColors.textSecondary,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AquaText.body2Medium(
                text: context.loc.maxLabel,
                color: context.aquaColors.textSecondary,
              ),
              const SizedBox(width: 4),
              AquaText.body2Medium(
                text: maxLimit ?? '',
                color: context.aquaColors.textSecondary,
                textDirection: TextDirection.ltr,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
