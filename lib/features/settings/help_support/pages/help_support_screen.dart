import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/urls.dart' as urls;
import 'package:aqua/features/settings/shared/providers/version_provider.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelpSupportScreen extends ConsumerWidget {
  static const routeName = '/helpSupportScreen';

  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquaVersion = ref.watch(versionProvider);
    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.getHelpSupportScreenTitle,
        backgroundColor: Theme.of(context).colors.appBarBackgroundColor,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //ANCHOR - Description
            const SizedBox(height: 28.0),
            Padding(
                padding: const EdgeInsets.only(left: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.loc.contactUsHelpSupportScreenHeaderText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 28.0,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            )),
                    const SizedBox(height: 16.0),
                    Text(
                        context
                            .loc.contactUsHelpSupportScreenHeaderSubtitleText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w500,
                              height: 1.25,
                            )),
                  ],
                )),
            const SizedBox(height: 32.0),
            //ANCHOR - Buttons
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20.0,
              mainAxisSpacing: 25.0,
              childAspectRatio: 175 / 190,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              children: [
                HelpSupportWidgetButton(
                  svgPicture: Svgs.zendeskLogo,
                  buttonSubText: context.loc.zendeskSubtitle,
                  buttonText: context.loc.zendeskTitle,
                  onPressed: () {
                    ref
                        .read(urlLauncherProvider)
                        .open(getAquaZendeskUrl(aquaVersion.valueOrNull ?? ''));
                  },
                ),
                HelpSupportWidgetButton(
                    svgPicture: UiAssets.svgs.faq.path,
                    buttonSubText: context.loc.faqSubtitle,
                    buttonText: context.loc.faqTitle,
                    onPressed: () {
                      ref
                          .read(urlLauncherProvider)
                          .open(urls.aquaZendeskFaqUrl);
                    }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class HelpSupportWidgetButton extends StatelessWidget {
  const HelpSupportWidgetButton({
    super.key,
    required this.svgPicture,
    required this.buttonText,
    required this.buttonSubText,
    this.onPressed,
    this.enabled = true,
  });

  final String svgPicture;
  final String buttonText;
  final String buttonSubText;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed != null ? 1 : 0.5,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    child: SizedBox(
                      height: 22.0,
                      child: AspectRatio(
                        aspectRatio: 1.0,
                        child: SvgPicture.asset(
                          svgPicture,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).colorScheme.surface,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //ANCHOR - Title
                  Text(
                    buttonText,
                    textAlign: TextAlign.left,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 20.0),
                  ),
                  const SizedBox(height: 8.0),
                  //ANCHOR - Subtitle
                  Text(
                    buttonSubText,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
