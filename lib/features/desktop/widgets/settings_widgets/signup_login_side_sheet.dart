import 'package:aqua/features/desktop/constants/constants.dart';
import 'package:aqua/features/desktop/layout/layout.dart';
import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:pinput/pinput.dart';
import 'package:ui_components/ui_components.dart';

class Jan3AccountSideSheetMainWidget extends HookWidget {
  const Jan3AccountSideSheetMainWidget({
    required this.aquaColors,
    required this.loc,
    required this.isDarkMode,
    this.isMarketplaceFlow = false,
    super.key,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isDarkMode;
  final bool isMarketplaceFlow;

  @override
  Widget build(BuildContext context) {
    final textEditingController = useTextEditingController();
    if (isMarketplaceFlow) {
      return _MarketplaceFlowWidget(
          aquaColors: aquaColors,
          loc: loc,
          isDarkMode: isDarkMode,
          textEditingController: textEditingController);
    }
    return _SettingsFlowWidget(
        aquaColors: aquaColors,
        loc: loc,
        isDarkMode: isDarkMode,
        textEditingController: textEditingController);
  }

  static Future<void> show({
    required BuildContext context,
    required AppLocalizations loc,
    required AquaColors aquaColors,
    required bool isDarkMode,
    bool isMarketplaceFlow = false,
  }) async {
    await SideSheet.right(
      body: Jan3AccountSideSheetMainWidget(
        loc: loc,
        aquaColors: aquaColors,
        isDarkMode: isDarkMode,
        isMarketplaceFlow: isMarketplaceFlow,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class _MarketplaceFlowWidget extends StatelessWidget {
  const _MarketplaceFlowWidget({
    required this.aquaColors,
    required this.loc,
    required this.isDarkMode,
    required this.textEditingController,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isDarkMode;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: '',
      showBackButton: false,
      widgetAtBottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaButton.primary(
            text: loc.next,
            onPressed: () {
              Navigator.pop(context);
              Jan3AccountSideSheetPinWidget.show(
                aquaColors: aquaColors,
                context: context,
                loc: loc,
                isDarkMode: isDarkMode,
                isMarketplaceFlow: true,
              );
            },
          ),
          const SizedBox(height: 16),
          AquaButton.secondary(
            text: loc.goBack,
            onPressed: () {
              DolphinCardCarousalSideSheet.show(
                aquaColors: aquaColors,
                context: context,
                loc: loc,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: TermsAndPrivacyRichText(aquaColors: aquaColors),
          )
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: isDarkMode
              ? UiAssets.svgs.dark.jan3Logo.svg(
                  height: 32,
                )
              : UiAssets.svgs.light.jan3Logo.svg(
                  height: 32,
                ),
        ),
        const SizedBox(height: 24),
        AquaText.h4Medium(
          text: 'Sign Up / Log In',
          color: aquaColors.textPrimary,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 24),
          child: AquaText.body1Medium(
            text:
                'Enter your email to Sign Up or Log In to your JAN3 account. Your JAN3 account will be linking this specific wallet to external integrations, making it easier to access those services and more.',
            color: aquaColors.textSecondary,
            maxLines: 4,
          ),
        ),
        AquaTextField(
          label: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          controller: textEditingController,
        ),
      ],
    );
  }
}

class _SettingsFlowWidget extends StatelessWidget {
  const _SettingsFlowWidget({
    required this.aquaColors,
    required this.loc,
    required this.isDarkMode,
    required this.textEditingController,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isDarkMode;
  final TextEditingController textEditingController;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: loc.loginScreenTitle,
      showBackButton: false,
      widgetAtBottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaButton.primary(
            text: 'Get Code',
            onPressed: () {
              ///TODO: alson Api call to send code to email
              Navigator.pop(context);

              Jan3AccountSideSheetPinWidget.show(
                aquaColors: aquaColors,
                context: context,
                loc: loc,
                isDarkMode: isDarkMode,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: TermsAndPrivacyRichText(aquaColors: aquaColors),
          )
        ],
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: isDarkMode
              ? UiAssets.svgs.dark.jan3Logo.svg(
                  height: 32,
                )
              : UiAssets.svgs.light.jan3Logo.svg(
                  height: 32,
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: AquaText.body1Medium(
            text:
                'Enter your email to sign up or log in to your JAN3 account. We\'ll send you a one-time code to link this wallet and access integrations and services.',
            color: aquaColors.textSecondary,
            maxLines: 4,
          ),
        ),
        AquaTextField(
          label: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          controller: textEditingController,
        ),
      ],
    );
  }
}

class Jan3AccountSideSheetPinWidget extends HookConsumerWidget {
  const Jan3AccountSideSheetPinWidget({
    required this.aquaColors,
    required this.loc,
    required this.isDarkMode,
    this.isMarketplaceFlow = false,
    super.key,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isDarkMode;
  final bool isMarketplaceFlow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMarketplaceFlow) {
      return _MarketplacePinScreenWidget(
        aquaColors: aquaColors,
        loc: loc,
        isDarkMode: isDarkMode,
      );
    }
    return _SettingsPinScreenWidget(
      aquaColors: aquaColors,
      loc: loc,
      isDarkMode: isDarkMode,
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AppLocalizations loc,
    required AquaColors aquaColors,
    required bool isDarkMode,
    bool isMarketplaceFlow = false,
  }) async {
    await SideSheet.right<bool>(
      body: Jan3AccountSideSheetPinWidget(
        loc: loc,
        aquaColors: aquaColors,
        isDarkMode: isDarkMode,
        isMarketplaceFlow: isMarketplaceFlow,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class _MarketplacePinScreenWidget extends StatelessWidget {
  const _MarketplacePinScreenWidget({
    required this.aquaColors,
    required this.loc,
    required this.isDarkMode,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: '',
      showBackButton: true,
      widgetAtBottom: AquaButton.secondary(
        text: loc.goBack,
        onPressed: () {
          Navigator.pop(context);
          Jan3AccountSideSheetMainWidget.show(
            aquaColors: aquaColors,
            context: context,
            loc: loc,
            isDarkMode: isDarkMode,
            isMarketplaceFlow: true,
          );
        },
      ),
      onBackPress: () {
        Navigator.pop(context);
        Jan3AccountSideSheetMainWidget.show(
          aquaColors: aquaColors,
          context: context,
          loc: loc,
          isDarkMode: isDarkMode,
          isMarketplaceFlow: true,
        );
      },
      children: [
        AquaText.h4Medium(
          text: 'Enter Your Code',
          color: aquaColors.textPrimary,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 24, top: 8),
          child: AquaText.body1Medium(
            text: 'Please enter the code that was sent to user@email.com.',
            color: aquaColors.textSecondary,
            maxLines: 3,
          ),
        ),
        _PinFieldsWidget(
          aquaColors: aquaColors,
          isMarketplaceFlow: true,
          loc: loc,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () {},
            child: AquaText.body2SemiBold(
              text: 'Resend Code',
              color: aquaColors.accentBrand,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPinScreenWidget extends HookWidget {
  const _SettingsPinScreenWidget({
    required this.aquaColors,
    required this.loc,
    required this.isDarkMode,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    ///TODO: this should be desided by backend logic
    var mockUserReturning = useState(false);
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: mockUserReturning.value ? 'Welcome Back' : 'Enter Your Code',
      showBackButton: true,
      onClosePress: () {
        Navigator.pop(context);
      },
      onBackPress: () {
        Navigator.pop(context);
        Jan3AccountSideSheetMainWidget.show(
          aquaColors: aquaColors,
          context: context,
          loc: loc,
          isDarkMode: isDarkMode,
        );
      },
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: AquaText.body1Medium(
            text:
                'Please enter the code that was sent to user@email.com. We’ll create your JAN3 account and link it to this wallet.',
            color: aquaColors.textSecondary,
            maxLines: 3,
          ),
        ),
        _PinFieldsWidget(
          aquaColors: aquaColors,
          isMarketplaceFlow: false,
          loc: loc,
          isDarkMode: isDarkMode,
        ),
        const SizedBox(height: 24),
        Align(
          alignment: Alignment.center,
          child: InkWell(
            onTap: () {},
            child: AquaText.body2SemiBold(
              text: 'Resend Code',
              color: aquaColors.accentBrand,
            ),
          ),
        ),
      ],
    );
  }
}

class _PinFieldsWidget extends HookConsumerWidget {
  const _PinFieldsWidget({
    required this.aquaColors,
    required this.loc,
    required this.isMarketplaceFlow,
    required this.isDarkMode,
  });

  final AquaColors aquaColors;
  final AppLocalizations loc;
  final bool isMarketplaceFlow;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const otpDigitCount = 6;
    final pinController = useTextEditingController();
    final pinFocusNode = useFocusNode();

    final defaultPinTheme = useMemoized(
        () => PinTheme(
              width: 52,
              height: 56,
              textStyle: AquaTypography.h5SemiBold.copyWith(
                color: aquaColors.accentBrand,
              ),
              decoration: BoxDecoration(
                color: context.colors.jan3InputFieldBackgroundColor,
                border: Border.all(
                  color: Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
        [context.colors.jan3InputFieldBackgroundColor]);

    final focusedPinTheme = useMemoized(
        () => defaultPinTheme.copyWith(
              decoration: defaultPinTheme.decoration!.copyWith(
                border: Border.all(
                  color: context.colorScheme.primary,
                  width: 1,
                ),
              ),
            ),
        [defaultPinTheme, context.colorScheme.primary]);

    return Pinput(
      length: otpDigitCount,
      controller: pinController,
      focusNode: pinFocusNode,
      defaultPinTheme: defaultPinTheme,
      focusedPinTheme: focusedPinTheme,
      keyboardType: TextInputType.number,
      isCursorAnimationEnabled: false,
      pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
      onChanged: (value) {},
      onCompleted: (value) {
        if (isMarketplaceFlow) {
          DolphinCardWaitListSideSheet.show(
            aquaColors: aquaColors,
            context: context,
            loc: loc,
          );
        } else {
          ///TODO: if success remove side sheet and show success dialog
          Navigator.pop(context);
          AquaModalSheet.show(
            context,
            copiedToClipboardText: loc.copiedToClipboard,
            bottomPadding: MediaQuery.sizeOf(context).height / screenParts,
            title: 'Your JAN3 Account',
            illustration: isDarkMode
                ? UiAssets.svgs.dark.jan3MiniLogo.svg()
                : UiAssets.svgs.light.jan3MiniLogo.svg(),
            message:
                'This JAN3 account will be linked to your current wallet only. To log in and link another wallet, just repeat the process.',
            primaryButtonText: loc.commonGotIt,
            onPrimaryButtonTap: () {
              desktopGlobalKey.currentState!.context.pop();
            },
            colors: aquaColors,
          );
        }
      },
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
    );
  }
}
