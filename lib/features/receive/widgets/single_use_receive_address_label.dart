import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:ui_components/ui_components.dart';

class SingleUseReceiveAddressLabel extends StatelessWidget {
  const SingleUseReceiveAddressLabel({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AquaText.body2SemiBold(
      text: context.loc.commonSingleUseAddress,
      textAlign: TextAlign.center,
    );
  }
}
