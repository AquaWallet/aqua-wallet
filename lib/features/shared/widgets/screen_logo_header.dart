import 'package:flutter/widgets.dart';
import 'package:ui_components/ui_components.dart' hide AquaColors;

class ScreenLogoHeader extends StatelessWidget {
  const ScreenLogoHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: MediaQuery.sizeOf(context).height * 0.12),
        AquaIcon.aquaLogo(
          size: 48,
          color: AquaPrimitiveColors.palatinateBlue750,
        ),
      ],
    );
  }
}
