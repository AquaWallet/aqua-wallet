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

  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    logger.d('arguments: $arguments');
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
              AppLocalizations.of(context)!.sendAssetCompleteScreenIdLabel,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w400,
                  ),
            ),
            child: CopyableTextView(text: arguments.transactionId ?? ''),
          ),
          //ANCHOR - Shift ID
          if (arguments.asset.isSideshift || arguments.asset.isLightning) ...{
            ExternalServiceIdView(arguments: arguments),
          },
          //ANCHOR - Time
          TransactionInfoItem(
            label:
                AppLocalizations.of(context)!.sendAssetCompleteScreenTimeLabel,
            value: formattedTime,
            padding: EdgeInsets.symmetric(horizontal: 26.w),
          ),
          SizedBox(height: 18.h),
          //ANCHOR - Date
          TransactionInfoItem(
            label:
                AppLocalizations.of(context)!.sendAssetCompleteScreenDateLabel,
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
    required this.arguments,
  });

  final SendAssetArguments arguments;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.only(left: 26.w, right: 6.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            arguments.asset.isSideshift
                ? AppLocalizations.of(context)!
                    .sendAssetCompleteScreenShiftIdLabel
                : AppLocalizations.of(context)!
                    .sendAssetCompleteScreenBoltzIdLabel,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                ),
          ),
          SizedBox(height: 4.h),
          CopyableTextView(text: arguments.externalServiceTxId ?? ''),
        ],
      ),
    );
  }
}
