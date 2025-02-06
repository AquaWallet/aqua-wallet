import 'package:aqua/common/common.dart';
import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:aqua/config/router/extensions.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/private_integrations/private_integrations.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reactive_forms/reactive_forms.dart';

const _emailFormControlName = 'email';

class Jan3LoginScreen extends HookConsumerWidget {
  const Jan3LoginScreen({super.key});

  static const routeName = '/login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileState = ref.watch(jan3AuthProvider);
    final emailFormGroup = useMemoized(() => FormGroup({
          _emailFormControlName: FormControl<String>(
            validators: [
              Validators.required,
              Validators.email,
            ],
          ),
        }));

    ref.listen(jan3AuthProvider, (prev, next) {
      if (prev?.value == next.value) return;
      next.value?.maybeWhen(
        authenticated: (_) => context
          ..popUntilPath(AuthWrapper.routeName)
          ..push(DebitCardMyCardScreen.routeName),
        pendingOtpVerification: () => context.push(
          Jan3OtpVerificationScreen.routeName,
          extra: emailFormGroup.control(_emailFormControlName).value,
        ),
        orElse: () {},
      );
    });

    return Scaffold(
      backgroundColor: AquaColors.eerieBlack,
      appBar: AquaAppBar(
        backgroundColor: Colors.transparent,
        titleWidget: UiAssets.svgs.dark.jan3Logo.svg(),
        showActionButton: false,
        iconBackgroundColor: AquaColors.eerieBlack,
        iconForegroundColor: Colors.white,
      ),
      body: ReactiveForm(
        formGroup: emailFormGroup,
        // ANCHOR - Email input field and form errors
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                context.loc.loginScreenTitle,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.loc.loginScreenEmailPrompt,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AquaColors.dimMarble,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: AquaColors.charlestonGreen,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: AquaColors.dimMarble,
                    width: 1.0,
                  ),
                ),
                // ANCHOR - Email input field
                child: ReactiveTextField<String>(
                  formControlName: _emailFormControlName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validationMessages: {
                    ValidationMessage.required: (control) =>
                        context.loc.loginScreenFieldRequired,
                    ValidationMessage.email: (control) =>
                        context.loc.loginScreenInvalidEmail,
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AquaColors.charlestonGreen,
                    hintText: context.loc.loginScreenEmailHint,
                    hintStyle: const TextStyle(
                      color: AquaColors.dimMarble,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),

              if (profileState.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: AquaColors.portlandOrange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        profileState.error is ExceptionLocalized
                            ? (profileState.error as ExceptionLocalized)
                                .toLocalizedString(context)
                            : profileState.error.toString(),
                        style: const TextStyle(
                          color: AquaColors.portlandOrange,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              // ANCHOR - Email screen description
              Text(
                context.loc.loginScreenDescription,
                style: const TextStyle(
                  color: AquaColors.dimMarble,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              ReactiveFormConsumer(
                builder: (context, form, child) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: SizedBox(
                      width: double.infinity,
                      // ANCHOR - Continue button
                      child: ElevatedButton(
                        onPressed: (profileState.isLoading || form.invalid)
                            ? null
                            : () => ref.read(jan3AuthProvider.notifier).sendOtp(
                                  form.control(_emailFormControlName).value,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: form.valid
                              ? AquaColors.aquaGreen
                              : AquaColors.dimMarble,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          disabledBackgroundColor: AquaColors.dimMarble,
                        ),
                        child: profileState.isLoading
                            ? const CircularProgressIndicator()
                            : Text(
                                context.loc.loginScreenContinue,
                                style: const TextStyle(
                                  color: AquaColors.eerieBlack,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
