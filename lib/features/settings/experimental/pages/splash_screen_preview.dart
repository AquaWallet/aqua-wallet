import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class SplashScreenPreview extends HookConsumerWidget {
  static const routeName = '/splash-preview';

  const SplashScreenPreview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagLines = useMemoized(
      () => [
        context.loc.welcomeScreenDesc1,
        context.loc.welcomeScreenDesc2,
        context.loc.welcomeScreenDesc3,
        context.loc.welcomeScreenDesc4,
        context.loc.welcomeScreenDesc5,
        context.loc.welcomeScreenDesc6,
      ],
      [context.loc],
    );

    final currentIndex = useState(0);

    useEffect(() {
      final timer = Stream.periodic(const Duration(seconds: 2), (i) => i)
          .listen((_) =>
              currentIndex.value = (currentIndex.value + 1) % tagLines.length);
      return timer.cancel;
    }, [tagLines.length]);

    return SplashScreen(tagline: tagLines[currentIndex.value]);
  }
}
