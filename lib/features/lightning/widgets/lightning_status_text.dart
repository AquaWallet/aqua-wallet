import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:aqua/features/boltz/boltz.dart';
import 'package:aqua/features/lightning/lightning.dart';
import 'package:aqua/common/widgets/animated_status_text.dart';

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
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
              letterSpacing: .6,
              fontWeight: FontWeight.normal,
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
