import 'package:aqua/config/config.dart';
import 'package:aqua/features/home/home.dart';
import 'package:aqua/features/send/send.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class InsufficientBalanceSheet extends HookConsumerWidget {
  const InsufficientBalanceSheet({
    super.key,
    required this.asset,
  });

  final SendAssetArguments asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        children: [
          SizedBox(height: 88.h),
          //ANCHOR - Illustration
          SvgPicture.asset(
            Svgs.insufficientBalance,
            width: 92.w,
            height: 80.h,
          ),
          SizedBox(height: 42.h),
          //ANCHOR - Title
          Text(
            AppLocalizations.of(context)!.insufficientFundsSheetMessage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 20.sp,
                ),
          ),
          SizedBox(height: 16.h),
          //ANCHOR - Required Fee
          // Text(
          //   AppLocalizations.of(context)!
          //       .insufficientFundsSheetRequiredFee(fee),
          //   style: Theme.of(context).textTheme.labelMedium,
          // ),
          SizedBox(height: 11.h),
          //ANCHOR - Current Balance
          // Text(
          //   AppLocalizations.of(context)!
          //       .insufficientFundsSheetCurrentBalance(balance),
          //   style: Theme.of(context).textTheme.labelMedium,
          // ),
          SizedBox(height: 30.h),
          //ANCHOR - Bitcoin Card
          GetBitcoinCard(
              asset: asset,
              onTap: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
                ref.read(homeProvider).selectTab(1);
              }),
        ],
      ),
    );
  }
}
