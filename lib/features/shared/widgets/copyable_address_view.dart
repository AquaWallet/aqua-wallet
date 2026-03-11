import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/services.dart';
import 'package:ui_components/ui_components.dart';

class CopyableAddressView extends HookConsumerWidget {
  const CopyableAddressView({
    super.key,
    required this.address,
  });

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: context.aquaColors.surfacePrimary,
      child: InkWell(
        onTap: () async {
          HapticFeedback.mediumImpact();
          context.copyToClipboard(address);
        },
        splashColor: context.aquaColors.surfacePrimary,
        child: Row(
          children: [
            Expanded(
              child: AquaText.body2(
                text: address,
                maxLines: 3,
              ),
            ),
            const SizedBox(width: 24.0),
            AquaIcon.copy(
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
