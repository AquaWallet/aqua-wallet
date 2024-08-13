import 'package:aqua/common/exceptions/exception_localized.dart';
import 'package:aqua/common/widgets/aqua_elevated_button.dart';
import 'package:aqua/common/widgets/custom_error.dart';
import 'package:aqua/config/theme/app_styles.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LnurlWithdrawScreen extends HookConsumerWidget {
  const LnurlWithdrawScreen({super.key});

  static const routeName = '/lnurlWithdrawScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = useState('');
    final arguments =
        ModalRoute.of(context)?.settings.arguments as LNURLWithdrawParams;
    final maxWithdrawableSats = arguments.maxWithdrawable ~/
        1000; // maxWithdrawable is in millisats, convert to sats

    final showSuccesScreen = useCallback((receiveSatoshiAmount) {
      Navigator.of(context).pushReplacementNamed(
        LightningTransactionSuccessScreen.routeName,
        arguments: LightningSuccessArguments(
            satoshiAmount: receiveSatoshiAmount,
            type: LightningSuccessType.receive),
      );
    }, []);

    final processWithdrawal = useCallback(() async {
      try {
        //TODO: Need to show spinner

        final boltzResponse = await ref
            .read(legacyBoltzProvider)
            .createReverseSwap(maxWithdrawableSats);
        logger.d(
            "[LNURL] withdraw - invoice from boltz: ${boltzResponse.invoice}");

        // call lnurlwithdraw callback with boltz invoice
        await ref.read(lnurlProvider).callLnurlWithdraw(
            withdrawParams: arguments, invoice: boltzResponse.invoice);

        //TODO: Need to show fee breakdown + Change success screen to show actual received sats
        //TODO: Temp showing success screeen here, but need to listen to boltz swap status for claim completion before showing success screen
        showSuccesScreen(maxWithdrawableSats);
      } on ExceptionLocalized catch (e) {
        if (context.mounted) {
          errorMessage.value = e.toLocalizedString(context);
        }
      } catch (e) {
        logger.e("[LNURL] withdraw - error: $e");
        errorMessage.value = e.toString();
      }

      return null;
    }, []);

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.lnurlwWithdraw,
        showActionButton: false,
        backgroundColor: Theme.of(context).colors.altScreenBackground,
        iconBackgroundColor: Theme.of(context).colors.altScreenSurface,
      ),
      backgroundColor: Theme.of(context).colors.altScreenBackground,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        height: 50.h,
        margin: EdgeInsets.all(18.w),
        child: AquaElevatedButton(
          onPressed: () async {
            processWithdrawal();
          },
          child: Text(
              context.loc.lnurlwWithdrawPrompt(maxWithdrawableSats.toString())),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 60.h),
              alignment: Alignment.centerLeft,
              child: Text(
                context.loc.lnurlwTitle,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.left,
              ),
            ),

            const Spacer(),

            //ANCHOR - Fixed Error
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: CustomError(errorMessage: errorMessage.value),
            ),
            SizedBox(height: 140.h),
          ],
        ),
      ),
    );
  }
}
