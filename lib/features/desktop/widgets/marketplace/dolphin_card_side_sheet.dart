import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/settings/region/providers/providers.dart';
import 'package:aqua/features/settings/shared/providers/providers.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/shared/utils/debit_card_localizations_extension.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

const _kCardNumber = '4738293805948271';
const _cardCvv = '384';
const _columnOfFeatures = [
  'Reloadable at no cost',
  '\$4,000 Monthly Spend Limit',
  '1% fee on spend (\$1.00 min. spend)',
];

class DolphinCardSideSheet extends HookConsumerWidget {
  const DolphinCardSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    var isSupportedCountriesClicked = useState(false);

    final availableRegions = ref.read(availableRegionsProvider);
    final sizeOfScreen = MediaQuery.sizeOf(context);
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: isSupportedCountriesClicked.value ? loc.supportedCountries : '',
      showBackButton: false,
      widgetAtBottom: isSupportedCountriesClicked.value
          ? AquaButton.secondary(
              text: loc.goBack,
              onPressed: () => isSupportedCountriesClicked.value = false,
            )
          : Column(
              children: [
                AquaButton.primary(
                  text: loc.next,
                  onPressed: () => DolphinCardCarousalSideSheet.show(
                    context: context,
                    aquaColors: aquaColors,
                    loc: loc,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: AquaButton.secondary(
                    text: loc.goBack,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                TermsAndPrivacyRichText(aquaColors: aquaColors)
              ],
            ),
      children: [
        if (isSupportedCountriesClicked.value) ...[
          AquaText.body1Medium(
            text:
                'You may not use the card with merchants billing from or located in:',
            color: aquaColors.textSecondary,
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          availableRegions.when(
            data: (data) {
              return SizedBox(
                height: sizeOfScreen.height * 0.75,
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: List.generate(
                      data.length,
                      (index) => AquaText.body2Medium(
                        text: data[index].name +
                            (index != data.length - 1 ? ', ' : '.'),
                      ),
                    ),
                  ),
                ),
              );
            },
            error: (error, stackTrace) => const SizedBox.shrink(),
            loading: () => const CircularProgressIndicator(),
          ),
        ] else ...[
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AquaText.h4Medium(
                text: 'Reloadable Card',
                color: aquaColors.textPrimary,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => isSupportedCountriesClicked.value = true,
                child: AquaText.body2SemiBold(
                  text: loc.supportedCountries,
                  color: aquaColors.accentBrand,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: AquaDebitCard(
              style: CardStyle.style1,
              expiration: DateTime(2016, 7),
              pan: _kCardNumber,
              cvv: _cardCvv,
              text: loc.debitCardLocalizations,
            ),
          ),
          ...List.generate(_columnOfFeatures.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: RowCheckMarkAndTextWidget(
                aquaColors: aquaColors,
                text: _columnOfFeatures[index],
              ),
            );
          }),
        ],
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    return SideSheet.right(
      body: DolphinCardSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class DolphinCardCarousalSideSheet extends ConsumerWidget {
  const DolphinCardCarousalSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(
      prefsProvider.select(
        (p) => p.isDarkMode(context),
      ),
    );
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: '',
      showBackButton: false,
      widgetAtBottom: Column(
        children: [
          AquaButton.primary(
            text: loc.next,
            onPressed: () {
              Navigator.pop(context);

              Jan3AccountSideSheetMainWidget.show(
                context: context,
                loc: loc,
                aquaColors: aquaColors,
                isDarkMode: isDarkMode,
                isMarketplaceFlow: true,
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: AquaButton.secondary(
              text: loc.goBack,
              onPressed: () {
                Navigator.pop(context);
                DolphinCardSideSheet.show(
                  context: context,
                  aquaColors: aquaColors,
                  loc: loc,
                );
              },
            ),
          ),
        ],
      ),
      children: [
        AquaText.h4Medium(
            text: 'Choose Your Style', color: aquaColors.textPrimary),
        const SizedBox(height: 20),
        Container(
          constraints: const BoxConstraints(
            maxWidth: AquaDebitCard.width + 48,
          ),
          child: AquaCarousel(
            maxContentHeight: AquaDebitCard.height,
            colors: aquaColors,
            children: [
              for (final style in CardStyle.values.take(4)) ...{
                AquaDebitCard(
                  style: style,
                  expiration: DateTime(2016, 7),
                  pan: _kCardNumber,
                  cvv: _cardCvv,
                  text: loc.debitCardLocalizations,
                ),
              },
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: DolphinCardCarousalSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

class DolphinCardWaitListSideSheet extends ConsumerWidget {
  const DolphinCardWaitListSideSheet({
    required this.loc,
    required this.aquaColors,
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: '',
      showBackButton: false,
      widgetAtBottom: AquaButton.primary(
        text: 'Got It!',
        onPressed: () {
          Navigator.pop(context);

          ///TODO: go to dolphin main screen?
        },
      ),
      children: [
        AquaText.h4Medium(
          text: 'You’ve been added to the waitlist!',
          color: aquaColors.textPrimary,
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        AquaText.body1(
          text: 'You will receive an email when it\'s available.',
          color: aquaColors.textSecondary,
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        const SizedBox(height: 24),
        AquaDebitCard(
          style: CardStyle.style1,
          expiration: DateTime(2016, 7),
          pan: _kCardNumber,
          cvv: _cardCvv,
          text: loc.debitCardLocalizations,
        ),
      ],
    );
  }

  static Future<void> show({
    required BuildContext context,
    required AquaColors aquaColors,
    required AppLocalizations loc,
  }) {
    Navigator.pop(context);
    return SideSheet.right(
      body: DolphinCardWaitListSideSheet(
        aquaColors: aquaColors,
        loc: loc,
      ),
      context: context,
      colors: aquaColors,
    );
  }
}

/// Custom widget

class RowCheckMarkAndTextWidget extends StatelessWidget {
  const RowCheckMarkAndTextWidget({
    required this.aquaColors,
    required this.text,
    super.key,
  });

  final AquaColors aquaColors;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: aquaColors.surfaceBorderSecondary,
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: AquaIcon.check(
            color: aquaColors.accentBrand,
            padding: const EdgeInsets.all(4),
            size: 18,
          ),
        ),
        AquaText.body1Medium(
          text: text,
          color: aquaColors.textPrimary,
        ),
      ],
    );
  }
}

///Region ban or API error
class FeatureUnavailableSideSheet extends StatelessWidget {
  const FeatureUnavailableSideSheet({
    required this.loc,
    required this.aquaColors,
    required this.mainText,
    required this.description,
    this.title = '',
    super.key,
  });

  final AppLocalizations loc;
  final AquaColors aquaColors;

  final String title;
  final String mainText;
  final String description;

  @override
  Widget build(BuildContext context) {
    return SettingsContentForSideSheet(
      aquaColors: aquaColors,
      title: title,
      widgetAtBottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AquaButton.primary(
            text: 'Got It!',
            onPressed: () => Navigator.pop(context),
          ),
          AquaButton.secondary(
            text: loc.commonContactSupport,
            onPressed: () {
              ///TODO: add what happens on contact support
            },
          ),
        ],
      ),
      children: [
        Container(
          width: 88,
          height: 88,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: aquaColors.accentWarningTransparent,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: aquaColors.accentWarning,
              borderRadius: BorderRadius.circular(100),
            ),
            child: AquaIcon.warning(
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 24),
        AquaText.h4Medium(
          text: mainText,
          color: aquaColors.textPrimary,
        ),
        const SizedBox(height: 8),
        AquaText.body1(
          text: description,
          color: aquaColors.textSecondary,
        ),
      ],
    );
  }
}
