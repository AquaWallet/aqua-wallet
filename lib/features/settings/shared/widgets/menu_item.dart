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
        color: Theme.of(context).colors.background,
        borderRadius: BorderRadius.circular(12.0),
        child: Opacity(
          opacity: isEnabled ? 1 : 0.5,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: BorderRadius.circular(12.0),
            child: Ink(
              height: 68.0,
              padding: const EdgeInsets.only(left: 8.0, top: 4, bottom: 4),
              child: Row(
                children: [
                  //ANCHOR - Icon
                  assetName.isNotEmpty
                      ? Container(
                          width: 36.0,
                          height: 36.0,
                          padding: iconPadding ?? const EdgeInsets.all(8.0),
                          child: assetName.contains('flags/') == true
                              ? Center(
                                  child: CountryFlag(
                                    svgAsset: assetName,
                                  ),
                                )
                              : SvgPicture.asset(assetName,
                                  fit: BoxFit.scaleDown,
                                  colorFilter: color != null
                                      ? ColorFilter.mode(
                                          Theme.of(context).colors.settingsIcon,
                                          BlendMode.srcIn,
                                        )
                                      : null),
                        )
                      : Container(),
                  //ANCHOR - Label
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
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
      trailing: const Padding(
        padding: EdgeInsets.only(right: 9.0),
        child: _ArrowIcon(),
      ),
    );
  }

  factory MenuItemWidget.labeledArrow({
    Key? key,
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
      key: key,
      isEnabled: isEnabled,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      color: color,
      iconPadding: iconPadding,
      trailing: Expanded(
        flex: 5,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  label,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 12.0, right: 9.0),
              child: _ArrowIcon(),
            ),
          ],
        ),
      ),
    );
  }

  factory MenuItemWidget.switchItem({
    Key? key,
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
      key: key,
      isEnabled: enabled,
      onPressed: onPressed,
      assetName: assetName,
      title: title,
      iconPadding: iconPadding,
      color: multicolor ? null : Theme.of(context).colors.onBackground,
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
      size: 15.0,
      color: Theme.of(context).colors.onBackground,
    );
  }
}
