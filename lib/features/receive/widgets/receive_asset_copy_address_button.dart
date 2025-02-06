import 'package:aqua/common/widgets/middle_ellipsis_text.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class CopyAddressButton extends HookConsumerWidget {
  const CopyAddressButton({
    super.key,
    required this.address,
  });

  final String address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      color: Theme.of(context).colors.receiveAddressCopySurface,
      child: InkWell(
        onTap: address.isEmpty
            ? null
            : () async {
                HapticFeedback.mediumImpact();
                await context.copyToClipboard(address);
              },
        splashColor: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        child: Container(
          width: double.maxFinite,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
          child: Row(
            children: [
              Expanded(
                child: MiddleEllipsisText(
                  text: address,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colors.onBackground,
                        fontWeight: FontWeight.bold,
                        height: 1.38,
                      ),
                  startLength: 40,
                  endLength: 40,
                  ellipsisLength: 3,
                ),
              ),
              const SizedBox(width: 24.0),
              SvgPicture.asset(
                Svgs.copy,
                width: 12.0,
                height: 12.0,
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colors.onBackground,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
