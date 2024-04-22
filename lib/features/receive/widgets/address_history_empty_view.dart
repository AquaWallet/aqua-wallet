import 'package:aqua/config/config.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(Svgs.noHistoryIconAddressHistory,
                width: 90.w,
                height: 112.h,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colors.addressHistoryNoHistoryIconColor,
                  BlendMode.srcIn,
                )),
          ],
        ),
        SizedBox(height: 30.h),
        Text(
          context.loc.receiveHistoryAddressesEmptyTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color:
                    Theme.of(context).colors.addressHistoryNoHistoryTextColor,
              ),
        ),
        SizedBox(height: 12.h),
        Text(
          context.loc.receiveHistoryAddressesEmptyDesc,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyMedium!
              .copyWith(color: AquaColors.cadetGrey),
        ),
        const Spacer(flex: 5),
      ],
    );
  }
}
