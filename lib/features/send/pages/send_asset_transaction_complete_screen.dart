import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/constants.dart';
import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:lottie/lottie.dart';

class SendAssetTransactionCompleteScreen extends HookConsumerWidget {
  const SendAssetTransactionCompleteScreen({super.key});

  static const routeName = '/sendAssetTransactionCompleteScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments = ModalRoute.of(context)?.settings.arguments
        as SendAssetCompletionArguments;
    final botevMode = ref.watch(prefsProvider.select((p) => p.isBotevMode));
    final amountToDisplay = ref.read(amountMinusFeesToDisplayProvider);
    final asset = ref.read(sendAssetProvider);

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        actionButtonAsset: Svgs.close,
        actionButtonIconSize: 13.r,
        onActionButtonPressed: () =>
            Navigator.of(context).popUntil((r) => r.isFirst),
        title: context.loc.sendAssetScreenTitle,
      ),
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Column(
          children: [
            SizedBox(height: 18.h),
            Lottie.asset(
              botevMode ? animation.tickBotev : animation.tick,
              repeat: false,
              width: 100.r,
              height: 100.r,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 7.h),
            //ANCHOR - Amount Title
            Text(
              context.loc.sendAssetCompleteScreenAmountTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            SizedBox(height: 14.h),
            //ANCHOR - Amount
            Text(
              '$amountToDisplay ${asset.symbol}',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
            SizedBox(height: 19.h),
            //ANCHOR - Transaction Info
            const TransactionInfoCard(),
            SizedBox(height: 20.h),
            //ANCHOR - Transaction ID
            TransactionIdCard(arguments: arguments),
            const Spacer(),
            //ANCHOR - Button
            SizedBox(
              width: double.maxFinite,
              child: BoxShadowElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((r) => r.isFirst),
                child: Text(
                  context.loc.sendAssetCompleteScreenDoneButton,
                ),
              ),
            ),
            SizedBox(height: kBottomPadding),
          ],
        ),
      ),
    );
  }
}
