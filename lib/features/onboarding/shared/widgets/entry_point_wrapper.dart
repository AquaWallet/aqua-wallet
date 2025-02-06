import 'dart:math';

import 'package:aqua/data/data.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class EntryPointWrapper extends HookConsumerWidget {
  const EntryPointWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final taglines = useMemoized(() => [
          context.loc.welcomeScreenDesc1,
          context.loc.welcomeScreenDesc2,
          context.loc.welcomeScreenDesc3,
          context.loc.welcomeScreenDesc4,
          context.loc.welcomeScreenDesc5,
        ]);
    final description = useState(taglines[Random().nextInt(5)]);
    final onSwitchTagline = useCallback(() {
      final currentIndex = taglines.indexOf(description.value);
      final nextTagline = taglines[(currentIndex + 1) % taglines.length];
      description.value = nextTagline;
    }, [description.value]);

    ref.listen(aquaConnectionProvider, (_, asyncValue) {
      if (ref.read(initAppProvider).isLoading == true) {
        // ignore before app is initialized
        return;
      }

      return asyncValue.maybeWhen(
          data: (_) {
            /**
             * When connected make sure we are on the HomeScreen.
             * Required for wallet restore flow.
             */
            context.pushReplacement(HomeScreen.routeName);
          },
          orElse: () {});
    });
    final mnemonicFuture =
        useFuture(ref.read(secureStorageProvider).get(StorageKeys.mnemonic));

    return ref.watch(initAppProvider).maybeWhen(
              data: (_) {
                return ref.watch(aquaConnectionProvider).when(data: (data) {
                  final (mnemonic, err) = mnemonicFuture.data!;
                  if (err != null || mnemonic == null) {
                    // Need to redirect users without wallet to onboarding
                    return WelcomeScreen(
                      description: description.value,
                      onSwitchTagline: onSwitchTagline,
                    );
                  }
                  return const HomeScreen();
                }, error: (error, stackTrace) {
                  return WelcomeScreen(
                    description: description.value,
                    onSwitchTagline: onSwitchTagline,
                  );
                }, loading: () {
                  return SplashScreen(
                    description: description.value,
                    onSwitchTagline: onSwitchTagline,
                  );
                });
              },
              orElse: () => SplashScreen(
                description: description.value,
                onSwitchTagline: onSwitchTagline,
              ),
            ) ??
        Container();
  }
}
