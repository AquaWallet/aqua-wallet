import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

class CopyableAddressView extends HookConsumerWidget {
  const CopyableAddressView({
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
        onTap: () async {
          HapticFeedback.mediumImpact();
          context.copyToClipboard(address);
        },
        splashColor: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
        child: Container(
          width: double.maxFinite,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: Theme.of(context).colors.receiveContentBoxBorder,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 23.0,
            vertical: 12.0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  address,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colors.onBackground,
                        fontWeight: FontWeight.w400,
                        height: 1.38,
                      ),
                ),
              ),
              const SizedBox(width: 24.0),
              SvgPicture.asset(
                Svgs.copy,
                width: 12.0,
                height: 12.0,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colors.onBackground, BlendMode.srcIn),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
