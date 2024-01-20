import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/shared/shared.dart';

/// Does the authentication and displays the sensitive information based on its
/// result
class AuthWrapper extends HookConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //TODO add auth in the future
    return const EntryPointWrapper();
  }
}
