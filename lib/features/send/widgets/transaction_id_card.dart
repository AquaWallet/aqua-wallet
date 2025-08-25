import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class TransactionIdCard extends HookConsumerWidget {
  const TransactionIdCard({
    super.key,
    required this.arguments,
  });

  final SendAssetCompletionArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = useMemoized(() => arguments.asset, [arguments]);
    final timestamp = useMemoized(() => arguments.createdAt, [arguments]);
    final formattedTime = useMemoized(
      () => DateTime.fromMicrosecondsSinceEpoch(timestamp).HHmma(),
      [timestamp],
    );
    final formattedDate = useMemoized(
      () => DateTime.fromMicrosecondsSinceEpoch(timestamp).ddMMMMyyyy(),
      [timestamp],
    );

    return BoxShadowCard(
      color: context.colors.altScreenSurface,
      bordered: true,
      borderColor: context.colors.cardOutlineColor,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          //ANCHOR - Transaction ID
          _CopyableTransactionId(
            label: context.loc.transactionID,
            transactionId: arguments.txId,
          ),
          const SizedBox(height: 18),
          //ANCHOR - Shift ID
          if (asset.isAltUsdt || asset.isLightning) ...{
            _CopyableTransactionId(
              label: asset.isAltUsdt ? context.loc.swapId : context.loc.boltzId,
              transactionId: arguments.serviceOrderId ?? '-',
            ),
            const SizedBox(height: 18),
          },
          //ANCHOR - Time
          TransactionInfoItem(
            label: context.loc.time,
            value: formattedTime,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 14),
          //ANCHOR - Date
          TransactionInfoItem(
            label: context.loc.date,
            value: formattedDate,
            padding: const EdgeInsets.symmetric(horizontal: 24),
          ),
          const SizedBox(height: 22),
        ],
      ),
    );
  }
}

class _CopyableTransactionId extends HookConsumerWidget {
  const _CopyableTransactionId({
    required this.label,
    required this.transactionId,
  });

  final String label;
  final String transactionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ExpandableContainer(
      padding: const EdgeInsetsDirectional.only(start: 24, end: 20),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: context.colors.onBackground,
          fontFamily: UiFontFamily.helveticaNeue,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
      ),
      child: CopyableTextView(
        text: transactionId,
        iconSize: 14,
        margin: const EdgeInsetsDirectional.only(top: 2, end: 4),
        textStyle: TextStyle(
          color: context.colorScheme.onTertiaryContainer,
          fontSize: 14,
          fontFamily: UiFontFamily.helveticaNeue,
          fontWeight: FontWeight.w700,
          height: 1.50,
        ),
      ),
    );
  }
}
