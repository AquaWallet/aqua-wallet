import 'dart:async';

import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AnimatedStatusText extends HookWidget {
  final String statusText;
  // animates three periods after the text
  final bool showDots;

  const AnimatedStatusText({
    super.key,
    required this.statusText,
    required this.showDots,
  });

  @override
  Widget build(BuildContext context) {
    final dotCount = useState(0);

    useEffect(() {
      if (!showDots) return null;

      final timer = Timer.periodic(const Duration(milliseconds: 1000), (_) {
        dotCount.value = (dotCount.value + 1) % 4;
      });

      return () => timer.cancel();
    }, [showDots]);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // aids in centering, but really impossible to center since width animates
        const SizedBox(width: 12),
        Text(
          statusText,
          style: TextStyle(
            letterSpacing: 0,
            wordSpacing: 0,
            height: 0,
            fontSize: 30.sp,
            fontWeight: FontWeight.w500,
            fontFamily: UiFontFamily.dMSans,
            color: context.colorScheme.onPrimary,
          ),
        ),
        if (showDots)
          SizedBox(
            width: 30,
            child: Text(
              '.' * dotCount.value,
              textAlign: TextAlign.left,
              style: context.textTheme.headlineSmall?.copyWith(
                letterSpacing: 0,
                wordSpacing: 0,
                height: 0,
                fontSize: 30.sp,
                fontWeight: FontWeight.w500,
                fontFamily: UiFontFamily.dMSans,
                color: context.colorScheme.onPrimary,
              ),
            ),
          ),
      ],
    );
  }
}
