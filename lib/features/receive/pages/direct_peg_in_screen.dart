import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/data/data.dart';
import 'package:coin_cz/features/receive/receive.dart';
import 'package:coin_cz/features/settings/settings.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/features/sideswap/swap.dart';
import 'package:coin_cz/logger.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DirectPegInScreen extends HookConsumerWidget {
  const DirectPegInScreen({super.key});

  static const routeName = '/directPegInScreen';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(directPegInProvider).mapOrNull(
          orderCreated: (s) => s.order,
        );
    final sideswapStatus = ref.watch(sideswapStatusStreamResultStateProvider);

    final minAmount = useMemoized(() {
      final amount = sideswapStatus?.minPegInAmount;
      if (amount == null) {
        return null;
      }
      return ref.read(formatterProvider).formatAssetAmountDirect(
            amount: amount,
            precision: 8,
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

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.receive,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        showActionButton: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 26.0),
            ReceiveAssetAddressQrCard(
              asset: Asset.btc(),
              isDirectPegIn: true,
              address: order?.pegAddress ?? '',
            ),
            if (minAmount != null) ...[
              const SizedBox(height: 21.0),
              Text(
                context.loc.receiveAssetScreenDirectPegInMinAmount(minAmount),
                style: context.textTheme.titleSmall,
              ),
            ],
            const SizedBox(height: 21.0),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 30.0),
              child: const PegInfoMessage(
                isPegIn: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
