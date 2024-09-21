import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MenuItemWidget extends StatelessWidget {
  const MenuItemWidget({
    super.key,
    this.assetName = '',
    required this.title,
    required this.onPressed,
    this.trailing,
    this.color,
    this.iconPadding,
    this.isEnabled = true,
  });

  final String assetName;
  final String title;
  final VoidCallback onPressed;
  final Widget? trailing;
  final Color? color;
  final bool isEnabled;
  final EdgeInsets? iconPadding;

  @override
  Widget build(BuildContext context) {
    return Material(
        color: Theme.of(context).colorScheme.background,
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
                    decoration: BoxDecoration(
                      color: Theme.of(context).colors.iconBackground,
                      borderRadius: BorderRadius.circular(100.r),
                    ),
                    child: assetName.isNotEmpty
                        ? Container(
                            width: 36.r,
                            height: 36.r,
                            padding: iconPadding ?? EdgeInsets.all(8.r),
                            child: assetName.contains('flags/') == true
                                ? Center(
                                    child: CountryFlag(
                                      svgAsset: assetName,
                                    ),
                                  )
                                : SvgPicture.asset(
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
    Key? key,
    required BuildContext context,
    String assetName = '',
    Color? color,
    EdgeInsets? iconPadding,
    bool isEnabled = true,
    required String title,
    required VoidCallback onPressed,
  }) {
    return MenuItemWidget(
      key: key,
      isEnabled: isEnabled,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      color: color,
      iconPadding: iconPadding,
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
    EdgeInsets? iconPadding,
    required String title,
    required String label,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return MenuItemWidget(
      isEnabled: isEnabled,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      color: color,
      iconPadding: iconPadding,
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
    EdgeInsets? iconPadding,
    bool value = true,
    bool enabled = true,
    bool multicolor = false,
  }) {
    return MenuItemWidget(
      isEnabled: enabled,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      iconPadding: iconPadding,
      color: multicolor ? null : Theme.of(context).colorScheme.onBackground,
      trailing: Transform.scale(
        scaleY: .7,
        scaleX: .7,
        child: CupertinoSwitch(
          onChanged: enabled ? (_) => onPressed.call() : null,
          activeColor: Theme.of(context).colorScheme.secondary,
          trackColor: Theme.of(context).colorScheme.onSurface,
          value: value,
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
