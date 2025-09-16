import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class ClearInputButton extends ConsumerWidget {
  const ClearInputButton({
    super.key,
    this.onTap,
  });

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Ink(
          color: Colors.transparent,
          padding: EdgeInsets.zero,
          child: SvgPicture.asset(
            Svgs.clearInput,
          ),
        ),
      ),
    );
  }
}
