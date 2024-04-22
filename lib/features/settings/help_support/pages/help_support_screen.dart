import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/urls.dart' as urls;
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HelpSupportScreen extends ConsumerWidget {
  static const routeName = '/helpSupportScreen';

  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            SizedBox(height: 28.h),
            Padding(
                padding: EdgeInsets.only(left: 30.w),
                child: Text(context.loc.contactUsHelpSupportScreenHeaderText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 26.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ))),
            SizedBox(height: 57.h),
            //ANCHOR - Buttons
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20.w,
              mainAxisSpacing: 25.h,
              childAspectRatio: 175 / 190,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 28.w),
              children: [
                HelpSupportWidgetButton(
                  svgPicture: Svgs.zendeskLogo,
                  buttonSubText: context.loc.zendeskTitle,
                  onPressed: () {
                    ref.read(urlLauncherProvider).open(urls.aquaZendeskUrl);
                  },
                ),
                HelpSupportWidgetButton(
                  enabled: false,
                  svgPicture: Svgs.whatsappLogo,
                  buttonSubText: context.loc.whatsappTitle,
                ),
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
    required this.buttonSubText,
    this.onPressed,
    this.enabled = true,
  });

  final String svgPicture;
  final String buttonSubText;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed != null ? 1 : 0.5,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 14.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              //ANCHOR - Logo
              SvgPicture.asset(
                svgPicture,
                height: 65.h,
                fit: BoxFit.scaleDown,
                colorFilter: ColorFilter.mode(
                  enabled
                      ? Theme.of(context).colors.helpScreenLogoColor
                      : Theme.of(context).colorScheme.onInverseSurface,
                  enabled ? BlendMode.srcIn : BlendMode.saturation,
                ),
              ),
              //ANCHOR - Title
              Text(
                buttonSubText,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontSize: 20.sp),
              ),
              //ANCHOR - Subtitle
              Text(
                !enabled ? context.loc.marketplaceScreenComingSoon : '',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
