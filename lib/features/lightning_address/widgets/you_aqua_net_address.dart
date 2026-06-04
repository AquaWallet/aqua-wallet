import 'package:aqua/features/lightning_address/models/models.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

class YouAquaNetAddress extends StatelessWidget {
  const YouAquaNetAddress({
    super.key,
    required this.youColor,
    required this.aquaNetColor,
    required this.style,
  });

  final Color youColor;
  final Color aquaNetColor;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(context.loc.you, style: style.copyWith(color: youColor)),
        Text(kAquaNetDomain, style: style.copyWith(color: aquaNetColor)),
      ],
    );
  }
}
