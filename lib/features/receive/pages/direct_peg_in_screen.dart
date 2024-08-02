import 'package:aqua/config/config.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/features/swap/swap.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';
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
        logger.d('[DirectPegIn] PegStatus: $value');
      });

    return Scaffold(
      appBar: AquaAppBar(
        title: context.loc.receiveAssetScreenTitle,
        iconBackgroundColor:
            Theme.of(context).colors.addressFieldContainerBackgroundColor,
        showActionButton: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 26.h),
            ReceiveAssetAddressQrCard(
              asset: Asset.btc(),
              isDirectPegIn: true,
              address: order?.pegAddress ?? '',
            ),
            if (minAmount != null) ...[
              SizedBox(height: 21.h),
              Text(
                context.loc.receiveAssetScreenDirectPegInMinAmount(minAmount),
                style: context.textTheme.titleSmall,
              ),
            ],
            SizedBox(height: 21.h),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 30.w),
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
