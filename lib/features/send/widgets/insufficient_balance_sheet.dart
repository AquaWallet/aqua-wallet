import 'package:aqua/config/config.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

enum InsufficientFundsType {
  fee,
  sendAmount,
}

class InsufficientBalanceSheet extends HookConsumerWidget {
  const InsufficientBalanceSheet({
    super.key,
    this.type = InsufficientFundsType.sendAmount,
  });

  final InsufficientFundsType type;

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
            type == InsufficientFundsType.fee
                ? context.loc.insufficientFundsForFeesSheetMessage
                : context.loc.insufficientFundsSheetMessage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 20.sp,
                ),
          ),
          SizedBox(height: 16.h),
          //ANCHOR - Required Fee
          // Text(
          //   context.loc
          //       .insufficientFundsSheetRequiredFee(fee),
          //   style: Theme.of(context).textTheme.labelMedium,
          // ),
          SizedBox(height: 11.h),
          //ANCHOR - Current Balance
          // Text(
          //   context.loc
          //       .insufficientFundsSheetCurrentBalance(balance),
          //   style: Theme.of(context).textTheme.labelMedium,
          // ),
          SizedBox(height: 11.h),
          //ANCHOR - Bitcoin Card
          // GetBitcoinCard(onTap: () {
          //   Navigator.of(context).popUntil((route) => route.isFirst);
          //   ref.read(homeProvider).selectTab(1);
          // }),
          //ANCHOR - Reques Bitcoin Message
          Text(
            context.loc.sendAssetReviewNotEnoughFunds,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}
