import 'package:coin_cz/common/widgets/middle_ellipsis_text.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/utils/extensions/extensions.dart';
import 'package:flutter/material.dart';

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
        const SizedBox(height: 4.0),
        Row(
          children: [
            Expanded(
              child: MiddleEllipsisText(
                text: value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colors.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 13.0,
                      height: 1.5,
                    ),
                startLength: 30,
                endLength: 30,
                ellipsisLength: 3,
              ),
            ),
            Container(
              alignment: Alignment.centerRight,
              margin: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.copyToClipboard(value),
                  child: InkWell(
                    child: SvgPicture.asset(
                      Svgs.copy,
                      width: 16.0,
                      height: 16.0,
                      colorFilter: ColorFilter.mode(
                        Theme.of(context).colors.onBackground,
                        BlendMode.srcIn,
                      ),
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
