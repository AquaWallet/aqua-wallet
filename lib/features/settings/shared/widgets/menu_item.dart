import 'package:aqua/config/config.dart';
import 'package:country_flags/country_flags.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MenuItemWidget extends StatelessWidget {
  const MenuItemWidget({
    Key? key,
    this.assetName = '',
    required this.title,
    required this.onPressed,
    this.trailing,
    this.color,
    required this.isEnabled,
  }) : super(key: key);

  final String assetName;
  final String title;
  final VoidCallback onPressed;
  final Widget? trailing;
  final Color? color;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12.r),
            child: Ink(
              height: 68.h,
              padding: EdgeInsets.only(left: 8.w, top: 4, bottom: 4),
              child: Row(
                children: [
                  //ANCHOR - Icon
                  Container(
                    width: 50.r,
                    height: 50.r,
                    padding: assetName == Svgs.support
                        ? const EdgeInsets.all(4)
                        : null,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colors.iconBackground,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: assetName.isNotEmpty
                        ? SizedBox(
                            width: 36.r,
                            height: 36.r,
                            child: assetName.contains('assets/') == true
                                ? SvgPicture.asset(
                                    assetName,
                                    fit: BoxFit.scaleDown,
                                    colorFilter: color != null
                                        ? ColorFilter.mode(
                                            Theme.of(context)
                                                .colors
                                                .iconForeground,
                                            BlendMode.srcIn,
                                          )
                                        : null,
                                  )
                                : Center(
                                    child: CountryFlag.fromCountryCode(
                                      assetName,
                                      width: 20.r,
                                      height: 20.r,
                                      borderRadius: 5.r,
                                    ),
                                  ),
                          )
                        : Container(),
                  ),
                  //ANCHOR - Label
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(left: 20.w),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: assetName == Svgs.support ? null : color),
                      ),
                    ),
                  ),
                  //ANCHOR - Trailing
                  trailing ?? Container(),
                ],
              ),
            ),
          ),
        ));
  }

  factory MenuItemWidget.arrow({
    required BuildContext context,
    String assetName = '',
    Color? color,
    required String title,
    required VoidCallback onPressed,
  }) {
    return MenuItemWidget(
      isEnabled: true,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      color: color,
      trailing: Padding(
        padding: EdgeInsets.only(right: 9.w),
        child: const _ArrowIcon(),
      ),
    );
  }

  factory MenuItemWidget.labeledArrow({
    required BuildContext context,
    String assetName = '',
    Color? color,
    required String title,
    required String label,
    required VoidCallback onPressed,
    required bool isEnabled,
  }) {
    return MenuItemWidget(
      isEnabled: isEnabled,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      color: color,
      trailing: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Padding(
            padding: EdgeInsets.only(left: 12.w, right: 9.w),
            child: const _ArrowIcon(),
          ),
        ],
      ),
    );
  }

  factory MenuItemWidget.switchItem({
    required BuildContext context,
    String assetName = '',
    required String title,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return MenuItemWidget(
      isEnabled: true,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      trailing: Transform.scale(
        scaleY: .7,
        scaleX: .7,
        child: CupertinoSwitch(
          onChanged: (_) => onPressed.call(),
          activeColor: Theme.of(context).colorScheme.secondary,
          trackColor: Theme.of(context).colorScheme.onSurface,
          value: enabled,
          applyTheme: true,
        ),
      ),
    );
  }
}

class _ArrowIcon extends StatelessWidget {
  const _ArrowIcon();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.arrow_forward_ios_sharp,
      size: 15.r,
      color: Theme.of(context).colorScheme.onBackground,
    );
  }
}
