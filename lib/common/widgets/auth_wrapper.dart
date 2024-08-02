import 'package:aqua/config/constants/svgs.dart';
import 'package:aqua/features/onboarding/onboarding.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

/// Does the authentication and displays the sensitive information based on its
/// result
class AuthWrapper extends HookConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final biometricAuthSuccess = useState(false);
    final biometricAuthEnabled =
        ref.watch(prefsProvider.select((p) => p.isBiometricEnabled));
    final canAuthenticateWithBiometric =
        ref.watch(biometricAuthProvider).asData?.value.available ?? false;

    final requestBiometricAuth = useCallback(() async {
      biometricAuthSuccess.value = false;
      final success = await ref
          .read(biometricAuthProvider.notifier)
          .authenticate(reason: context.loc.biometricAuthenticationDescription);
      biometricAuthSuccess.value = success;
    }, []);

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).aqua(aquaColorNav: true);
      });
      return null;
    }, []);

    //ANCHOR - Request biometric auth on screen startup
    useEffect(() {
      if (biometricAuthEnabled && canAuthenticateWithBiometric) {
        Future.delayed(
          const Duration(milliseconds: 250),
          requestBiometricAuth,
        );
      }
      return null;
    }, []);

    if (!biometricAuthEnabled || biometricAuthSuccess.value) {
      return const EntryPointWrapper();
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 46.h),
          //ANCHOR - Logo
          SvgPicture.asset(
            Svgs.aquaLogo,
            height: 42.h,
          ),
          const Spacer(),
          //ANCHOR - Auth Button
          GestureDetector(
            onTap: requestBiometricAuth,
            child: SvgPicture.asset(
              Svgs.unlock,
              width: 106.w,
              height: 112.h,
            ),
          ),
          SizedBox(height: 36.h),
          //ANCHOR - Description
          Text(
            context.loc.biometricUnlockScreenDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.2,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
          ),
          const Spacer(),
          SizedBox(height: 148.h),
        ],
      ),
    );
  }
}
