import 'dart:async';

import 'package:aqua/config/config.dart';
import 'package:aqua/constants.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/lightning/widgets/lightning_status_text.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';

const _slideAnimationDuration = Duration(milliseconds: 300);
const _scaleAnimationDuration = Duration(milliseconds: 300);
const _fadeAnimationDuration = Duration(milliseconds: 200);

class LightningTransactionSuccessScreen extends HookConsumerWidget {
  const LightningTransactionSuccessScreen({super.key, required this.arguments});
  final LightningSuccessArguments arguments;

  static const routeName = '/lightningTransactionSuccessScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final satoshiAmountFormatted = useMemoized(() {
      // TODO - remove the hardcoded 'en_US' but we need to be consistent
      // throughout the app
      return NumberFormat.decimalPattern('en_US')
          .format(arguments.satoshiAmount);
    });

    //ANCHOR - Force status bar colors
    useEffect(() {
      Future.delayed(const Duration(milliseconds: 250), () {
        ref.read(systemOverlayColorProvider(context)).aqua(aquaColorNav: true);
      });
      return null;
    }, []);

    //ANCHOR - Slide animation

    final slideAnimationController =
        useAnimationController(duration: _slideAnimationDuration);
    final slideAnimation = Tween(begin: const Offset(0, -3), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: slideAnimationController,
      curve: Curves.easeOutBack,
    ));

    useEffect(() {
      Future.delayed(
        _slideAnimationDuration,
        () => slideAnimationController.forward(),
      );
      return () => slideAnimationController.dispose();
    }, []);

    //ANCHOR - Scale animation

    final scaleAnimationController =
        useAnimationController(duration: _scaleAnimationDuration);
    final scaleAnimation = Tween(begin: 0.75, end: 1.0).animate(CurvedAnimation(
      parent: scaleAnimationController,
      curve: Curves.elasticOut,
    ));

    slideAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        slideAnimationController.stop();
        scaleAnimationController.forward();
      }
    });

    //ANCHOR - Fade animation

    final fadeAnimationController =
        useAnimationController(duration: _fadeAnimationDuration);
    final fadeAnimation = useAnimation(CurvedAnimation(
      parent: fadeAnimationController,
      curve: Curves.easeOut,
    ));

    scaleAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        scaleAnimationController.stop();
        fadeAnimationController.forward();
      }
    });

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppStyle.backgroundGradient,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 28.0),
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: fadeAnimation,
              duration: _fadeAnimationDuration,
              child: Column(
                children: [
                  const SizedBox(height: 122.0),
                  //ANCHOR - Aqua Logo
                  UiAssets.svgs.dark.aquaLogo.svg(
                    width: 321.0,
                  ),
                  const Spacer(),
                  //ANCHOR - Lightning Graphic Placeholder
                  const SizedBox.square(dimension: 318.0),
                  //ANCHOR - Status Text
                  LightningStatusText(
                    type: arguments.type,
                    orderId: arguments.orderId,
                  ),
                  //ANCHOR - Amount
                  // TODO: asset amount widget
                  Text(
                    context.loc.lightningTransactionSuccessScreenAmountSats(
                      satoshiAmountFormatted,
                    ),
                    style: TextStyle(
                      height: 0,
                      letterSpacing: 0,
                      fontSize: 52.0,
                      fontWeight: FontWeight.w500,
                      fontFamily: UiFontFamily.dMSans,
                      color: context.colorScheme.onPrimary,
                    ),
                  ),
                  const Spacer(),
                  //ANCHOR - Button
                  SizedBox(
                    width: double.maxFinite,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(49.0),
                        backgroundColor: Colors.white,
                        foregroundColor: AquaColors.aquaBlue,
                        side: BorderSide(
                          width: 2.0,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9.0),
                        ),
                        textStyle: const TextStyle(
                          height: 0,
                          letterSpacing: 0,
                          wordSpacing: 0,
                          fontSize: 20.0,
                          fontWeight: FontWeight.w700,
                          fontFamily: UiFontFamily.dMSans,
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(systemOverlayColorProvider(context))
                            .themeBased();
                        context.go(HomeScreen.routeName);
                      },
                      child: Text(
                        context.loc.done,
                      ),
                    ),
                  ),
                  const SizedBox(height: kBottomPadding + 52.0),
                ],
              ),
            ),
            //ANCHOR - Lightning Graphic
            Container(
              alignment: Alignment.center,
              transformAlignment: Alignment.center,
              margin: const EdgeInsets.only(bottom: 120.0),
              child: SlideTransition(
                position: slideAnimation,
                child: ScaleTransition(
                  scale: scaleAnimation,
                  child: SvgPicture.asset(
                    Svgs.lightningBolt,
                    width: 300.0,
                    height: 300.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
