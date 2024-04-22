import 'package:aqua/config/config.dart';
import 'package:aqua/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LabelCopyableTextView extends StatelessWidget {
  const LabelCopyableTextView({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        SizedBox(height: 4.h),
        Row(
          children: [
            Expanded(
              child: Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.w400,
                      fontSize: 13.sp,
                      height: 1.5.h,
                    ),
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              margin: EdgeInsets.symmetric(horizontal: 12.w),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.copyToClipboard(value),
                  child: InkWell(
                    child: SvgPicture.asset(
                      Svgs.copy,
                      width: 16.r,
                      height: 16.r,
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onBackground,
                          BlendMode.srcIn),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
