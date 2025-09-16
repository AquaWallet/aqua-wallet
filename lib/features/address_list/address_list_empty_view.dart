import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter/material.dart';

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
                width: 90.0,
                height: 112.0,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colors.addressHistoryNoHistoryIconColor,
                  BlendMode.srcIn,
                )),
          ],
        ),
        const SizedBox(height: 30.0),
        Text(
          context.loc.noAddresses,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                color:
                    Theme.of(context).colors.addressHistoryNoHistoryTextColor,
              ),
        ),
        const SizedBox(height: 12.0),
        Text(
          context.loc.addressHistoryAddressesEmptyDescription,
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
