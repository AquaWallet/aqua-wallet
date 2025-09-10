import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:skeletonizer/skeletonizer.dart';

class DebitCardActionButton extends StatelessWidget {
  const DebitCardActionButton({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final SvgGenImage icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Ink(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Skeleton.leaf(
              child: BoxShadowContainer(
                width: 40,
                height: 40,
                color: Colors.transparent,
                padding: const EdgeInsets.all(7),
                bordered: true,
                borderWidth: 1,
                borderRadius: BorderRadius.circular(4),
                child: icon.svg(),
              ),
            ),
            const SizedBox(height: 8),
            Skeleton.leaf(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: UiFontFamily.inter,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
