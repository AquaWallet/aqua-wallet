import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/material.dart';

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
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        children: [
          const SizedBox(height: 88.0),
          //ANCHOR - Illustration
          SvgPicture.asset(
            Svgs.insufficientBalance,
            width: 92.0,
            height: 80.0,
          ),
          const SizedBox(height: 42.0),
          //ANCHOR - Title
          Text(
            type == InsufficientFundsType.fee
                ? context.loc.insufficientFundsForFeesSheetMessage
                : context.loc.insufficientFundsSheetMessage,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: 20.0,
                ),
          ),
          const SizedBox(height: 16.0),
          //ANCHOR - Required Fee
          // Text(
          //   context.loc
          //       .insufficientFundsSheetRequiredFee(fee),
          //   style: Theme.of(context).textTheme.labelMedium,
          // ),
          const SizedBox(height: 11.0),
          //ANCHOR - Current Balance
          // Text(
          //   context.loc
          //       .insufficientFundsSheetCurrentBalance(balance),
          //   style: Theme.of(context).textTheme.labelMedium,
          // ),
          const SizedBox(height: 11.0),
          //ANCHOR - Bitcoin Card
          // GetBitcoinCard(onTap: () {
          //   context.go(AuthWrapper.routeName);
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
