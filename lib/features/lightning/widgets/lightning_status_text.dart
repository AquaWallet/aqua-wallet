import 'package:aqua/common/widgets/animated_status_text.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/extensions/context_ext.dart';

class LightningStatusText extends HookConsumerWidget {
  final LightningSuccessType type;
  final String? orderId;

  const LightningStatusText({
    super.key,
    required this.type,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final swapStatus = ref.watch(boltzSwapStatusProvider(orderId ?? ''));

    String statusText = '';
    if (swapStatus.value?.status.isSuccess == true) {
      statusText = type == LightningSuccessType.send
          ? context.loc.lightningTransactionSuccessScreenSendTitle
          : context.loc.lightningTransactionSuccessScreenReceiveTitle;
    } else if (type == LightningSuccessType.send) {
      statusText = context.loc.lightningTransactionPendingScreenSendTitle;
    }

    if (type == LightningSuccessType.receive) {
      return Text(
        context.loc.lightningTransactionSuccessScreenReceiveTitle,
        style: TextStyle(
          letterSpacing: .6,
          fontSize: 30.sp,
          wordSpacing: 0,
          height: 1,
          color: context.colorScheme.onPrimary,
          fontWeight: FontWeight.normal,
          fontFamily: UiFontFamily.dMSans,
        ),
      );
    } else {
      return AnimatedStatusText(
        statusText: statusText,
        showDots: type == LightningSuccessType.send &&
            swapStatus.value?.status.isSuccess != true,
      );
    }
  }
}
