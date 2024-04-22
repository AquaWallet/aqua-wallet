import 'package:aqua/features/send/send.dart';
import 'package:aqua/features/settings/manage_assets/manage_assets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/logger.dart';
import 'package:aqua/utils/utils.dart';

class TransactionIdCard extends HookConsumerWidget {
  const TransactionIdCard({
    super.key,
    required this.arguments,
  });

  final SendAssetCompletionArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.d('arguments: $arguments');
    final asset = ref.read(sendAssetProvider);
    final timestamp = arguments.timestamp;
    final formattedTime = timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).HHmmaUTC()
        : '-';
    final formattedDate = timestamp != null
        ? DateTime.fromMicrosecondsSinceEpoch(timestamp).ddMMMMyyyy()
        : '-';
    return BoxShadowCard(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: 6.h),
          //ANCHOR - Transaction ID
          ExpandableContainer(
            padding: EdgeInsets.only(left: 26.w, right: 6.w),
            title: Text(
              context.loc.sendAssetCompleteScreenIdLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            child: CopyableTextView(text: arguments.txId ?? ''),
          ),
          //ANCHOR - Shift ID
          if (asset.isSideshift || asset.isLightning) ...{
            const ExternalServiceIdView(),
          },
          //ANCHOR - Time
          TransactionInfoItem(
            label: context.loc.sendAssetCompleteScreenTimeLabel,
            value: formattedTime,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 18.h),
          //ANCHOR - Date
          TransactionInfoItem(
            label: context.loc.sendAssetCompleteScreenDateLabel,
            value: formattedDate,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 26.h),
        ],
      ),
    );
  }
}

class ExternalServiceIdView extends HookConsumerWidget {
  const ExternalServiceIdView({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.read(sendAssetProvider);

    return Container(
      padding: EdgeInsets.only(left: 26.w, right: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            asset.isSideshift
                ? context.loc.sendAssetCompleteScreenShiftIdLabel
                : context.loc.sendAssetCompleteScreenBoltzIdLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
          ),
          SizedBox(height: 4.h),
          CopyableTextView(
              text: ref.read(externalServiceTxIdProvider(asset)) ?? ''),
        ],
      ),
    );
  }
}
