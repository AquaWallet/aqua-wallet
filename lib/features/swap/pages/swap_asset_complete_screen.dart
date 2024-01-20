import 'package:aqua/config/config.dart';
import 'package:aqua/config/constants/animations.dart' as animation;
import 'package:aqua/constants.dart';
import 'package:aqua/data/models/gdk_models.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:lottie/lottie.dart';

class SwapAssetCompleteScreen extends HookConsumerWidget {
  static const routeName = '/swapAssetCompleteScreen';

  const SwapAssetCompleteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)!.settings.arguments as (Asset, GdkTransaction);

    final model = ref.watch(swapDetailsProvider(arguments));

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: false,
        showActionButton: false,
        title: AppLocalizations.of(context)!.swapScreenTitle,
      ),
      body: model.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (uiModel) => _SuccessUi(uiModel: uiModel),
      ),
    );
  }
}

class _SuccessUi extends StatelessWidget {
  const _SuccessUi({
    required this.uiModel,
  });

  final SwapSuccessModel uiModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 26.w),
      child: Column(
        children: [
          SizedBox(height: 18.h),
          Lottie.asset(
            animation.tick,
            repeat: false,
            width: 100.r,
            height: 100.r,
            fit: BoxFit.cover,
          ),
          SizedBox(height: 7.h),
          //ANCHOR - Amount Title
          Text(
            AppLocalizations.of(context)!.swapScreenSuccessAmountTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          SizedBox(height: 10.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //ANCHOR - Amount
              Text(
                uiModel.receiveAmount,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(width: 6.w),
              //ANCHOR - Symbol
              Text(
                uiModel.receiveTicker,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AquaColors.graniteGray,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          SizedBox(height: 32.h),
          //ANCHOR - Transaction Info
          SwapInfoCard(uiModel: uiModel),
          SizedBox(height: 20.h),
          //ANCHOR - Transaction ID
          SwapIdCard(uiModel: uiModel),
          const Spacer(),
          //ANCHOR - Button
          SizedBox(
            width: double.maxFinite,
            child: BoxShadowElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(
                AppLocalizations.of(context)!.sendAssetCompleteScreenDoneButton,
              ),
            ),
          ),
          SizedBox(height: kBottomPadding),
        ],
      ),
    );
  }
}
