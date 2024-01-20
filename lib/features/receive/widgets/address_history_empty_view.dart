import 'package:aqua/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';

class AddressHistoryEmptyView extends StatelessWidget {
  const AddressHistoryEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 2),
        Container(
          margin: EdgeInsets.only(right: 24.w),
          child: SvgPicture.asset(Svgs.emptyAddressHistory,
              width: 97.w,
              height: 112.h,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.onBackground, BlendMode.srcIn)),
        ),
        SizedBox(height: 30.h),
        Text(
          AppLocalizations.of(context)!.receiveHistoryAddressesEmptyTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        SizedBox(height: 12.h),
        Text(
          AppLocalizations.of(context)!.receiveHistoryAddressesEmptyDesc,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(flex: 5),
      ],
    );
  }
}
