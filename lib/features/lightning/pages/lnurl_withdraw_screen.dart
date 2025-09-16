import 'package:coin_cz/common/exceptions/exception_localized.dart';
import 'package:coin_cz/common/widgets/aqua_elevated_button.dart';
import 'package:coin_cz/common/widgets/custom_error.dart';
import 'package:coin_cz/config/theme/app_styles.dart';
import 'package:coin_cz/features/boltz/boltz.dart';
import 'package:coin_cz/features/lightning/lightning.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LnurlWithdrawScreen extends HookConsumerWidget {
  const LnurlWithdrawScreen({super.key, required this.arguments});

  static const routeName = '/lnurlWithdrawScreen';
  final LNURLWithdrawParams arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorMessage = useState('');

    final maxWithdrawableSats = arguments.maxWithdrawable ~/
        1000; // maxWithdrawable is in millisats, convert to sats

    final showSuccesScreen = useCallback((receiveSatoshiAmount) {
      context.pushReplacement(
        LightningTransactionSuccessScreen.routeName,
        extra: LightningSuccessArguments(
            satoshiAmount: receiveSatoshiAmount,
            type: LightningSuccessType.receive),
      );
    }, []);

    final processWithdrawal = useCallback(() async {
      try {
        //TODO: Need to show spinner
        await ref
            .read(boltzReverseSwapProvider.notifier)
            .create(Decimal.fromInt(maxWithdrawableSats));
        final boltzState = ref.watch(boltzReverseSwapProvider);
        final invoice = boltzState.mapOrNull(qrCode: (s) => s.swap?.invoice);
        logger.debug("[LNURL] withdraw - invoice from boltz: $invoice");

        if (invoice != null) {
          // call lnurlwithdraw callback with boltz invoice
          await ref
              .read(lnurlProvider)
              .callLnurlWithdraw(withdrawParams: arguments, invoice: invoice);

          //TODO: Need to show fee breakdown + Change success screen to show actual received sats
          //TODO: Temp showing success screeen here, but need to listen to boltz swap status for claim completion before showing success screen
          showSuccesScreen(maxWithdrawableSats);
        }
      } on ExceptionLocalized catch (e) {
        if (context.mounted) {
          errorMessage.value = e.toLocalizedString(context);
        }
      } catch (e) {
        logger.error("[LNURL] withdraw - error: $e");
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
        height: 50.0,
        margin: const EdgeInsets.all(18.0),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 30.0, vertical: 60.0),
              alignment: Alignment.centerLeft,
              child: Text(
                context.loc.lnUrlWithdraw,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.left,
              ),
            ),

            const Spacer(),

            //ANCHOR - Fixed Error
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: CustomError(errorMessage: errorMessage.value),
            ),
            const SizedBox(height: 140.0),
          ],
        ),
      ),
    );
  }
}
