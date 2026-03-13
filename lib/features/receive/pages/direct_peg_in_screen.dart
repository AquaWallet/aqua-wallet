import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/data/data.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/sideswap/swap.dart';
import 'package:aqua/features/wallet/providers/display_units_provider.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class DirectPegInScreen extends HookConsumerWidget {
  const DirectPegInScreen({super.key});

  static const routeName = '/directPegInScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = ref.read(formatProvider);
    final order = ref.watch(directPegInProvider).mapOrNull(
          orderCreated: (s) => s.order,
        );
    final sideswapStatus = ref.watch(sideswapStatusStreamResultStateProvider);

    final minAmount = useMemoized(() {
      final amount = sideswapStatus?.minPegInAmount;
      if (amount == null) {
        return null;
      }
      return formatter.formatAssetAmount(
        amount: amount,
        asset: Asset.btc(),
        displayUnitOverride: SupportedDisplayUnits.btc,
      );
    }, [sideswapStatus]);

    ref
      ..listen(
        sideswapWebsocketProvider,
        (_, __) {},
      )
      ..listen(pegStatusProvider, (_, value) {
        logger.debug('[DirectPegIn] PegStatus: $value');
      });

    return DesignRevampScaffold(
      appBar: AquaTopAppBar(
        title: context.loc.internalSendReviewBitcoin,
        colors: context.aquaColors,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            ReceiveAssetAddressQrCard(
              asset: Asset.btc(),
              isDirectPegIn: true,
              address: order?.pegAddress ?? '',
            ),
            if (minAmount != null) ...[
              const SizedBox(height: 24.0),
              AquaCard.glass(
                borderRadius: BorderRadius.circular(8),
                child: AquaListItem(
                  title: context.loc.minimumAmount,
                  titleTrailing: '$minAmount ${context.loc.commonOnchain}',
                ),
              ),
            ],
            const SizedBox(height: 24.0),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: context.loc.directPegInDesc1,
                    style: AquaTypography.body2Medium
                        .copyWith(color: context.aquaColors.textTertiary),
                  ),
                  TextSpan(
                    text: context.loc.directPegInDesc2,
                    style: AquaTypography.body2Medium.copyWith(
                      color: context.aquaColors.textTertiary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => ref
                          .read(urlLauncherProvider)
                          .open(constants.aquaDirectPegInUrl),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
