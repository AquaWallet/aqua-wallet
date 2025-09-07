import 'package:aqua/common/common.dart';
import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:aqua/config/router/extensions.dart';
import 'package:aqua/features/account/account.dart';
import 'package:aqua/features/auth/auth.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:reactive_forms/reactive_forms.dart';

const _emailFormControlName = 'email';

class Jan3LoginScreen extends HookConsumerWidget {
  const Jan3LoginScreen({super.key});

  static const routeName = '/login';
  static const continueTo = 'continueTo';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueRoute =
        GoRouterState.of(context).uri.queryParameters[continueTo];

    final isDark =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));
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
        authenticated: (_, pendingCardCreation) {
          context.popUntilPath(AuthWrapper.routeName);

          if (continueRoute != null) {
            context.push(continueRoute);
          }
        },
        pendingOtpVerification: () => context.push(
          Jan3OtpVerificationScreen.routeName,
          extra: emailFormGroup.control(_emailFormControlName).value,
        ),
        orElse: () {},
      );
    });

    return Scaffold(
      appBar: AquaAppBar(
        backgroundColor: Colors.transparent,
        titleWidget: isDark
            ? UiAssets.svgs.dark.jan3Logo.svg()
            : UiAssets.svgs.light.jan3Logo.svg(),
        showActionButton: false,
      ),
      body: SafeArea(
        child: ReactiveForm(
          formGroup: emailFormGroup,
          // ANCHOR - Email input field and form errors
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  context.loc.loginScreenTitle,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: UiFontFamily.inter,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.loc.loginScreenEmailPrompt,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AquaColors.dimMarble,
                    fontFamily: UiFontFamily.inter,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                // ANCHOR - Email input field
                ReactiveTextField<String>(
                  formControlName: _emailFormControlName,
                  style: const TextStyle(
                    fontSize: 22,
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
                    fillColor: context.colors.jan3InputFieldBackgroundColor,
                    hintText: context.loc.loginScreenEmailHint,
                    hintStyle: const TextStyle(
                      color: AquaColors.dimMarble,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      fontFamily: UiFontFamily.inter,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        width: 1,
                        color: AquaColors.dimMarble,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        width: 1,
                        color: context.colorScheme.primary,
                      ),
                    ),
                  ),
                ),

                if (profileState.error != null) ...{
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
                  )
                },
                const SizedBox(height: 8),
                // ANCHOR - Email screen description
                Text(
                  context.loc.loginScreenDescription,
                  style: const TextStyle(
                    color: AquaColors.dimMarble,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                const Spacer(),
                // ANCHOR - Continue button
                ReactiveFormConsumer(
                  builder: (context, form, _) => AquaElevatedButton(
                    onPressed: (profileState.isLoading || form.invalid)
                        ? null
                        : () => ref.read(jan3AuthProvider.notifier).sendOtp(
                              form.control(_emailFormControlName).value,
                              ref.read(languageProvider(context)
                                  .select((p) => p.currentLanguage)),
                            ),
                    child: profileState.isLoading
                        ? const CircularProgressIndicator()
                        : Text(context.loc.loginScreenContinue),
                  ),
                ),
                const SizedBox(height: 10),
                // ANCHOR - Terms checkbox
                const Jan3Terms(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
