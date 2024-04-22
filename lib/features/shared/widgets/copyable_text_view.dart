import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_svg/svg.dart';

class CopyableTextView extends HookConsumerWidget {
  const CopyableTextView({
    super.key,
    this.textStyle,
    this.textAlign,
    this.iconSize,
    this.margin,
    required this.text,
  });

  final String text;
  final TextStyle? textStyle;
  final TextAlign? textAlign;
  final double? iconSize;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 18.h, right: 20.w, left: 30.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text,
              textAlign: textAlign ?? TextAlign.start,
              style: textStyle ??
                  Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground,
                        fontWeight: FontWeight.w400,
                        fontSize: 13.sp,
                      ),
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.copyToClipboard(text),
                child: InkWell(
                  child: SvgPicture.asset(
                    Svgs.copy,
                    width: iconSize ?? 12.r,
                    height: iconSize ?? 12.r,
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
    );
  }
}
