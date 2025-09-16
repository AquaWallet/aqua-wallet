import 'package:coin_cz/common/widgets/colored_text.dart';
import 'package:coin_cz/common/widgets/middle_ellipsis_text.dart';
import 'package:coin_cz/config/config.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/extensions/context_ext.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

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
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colors.onBackground,
                    height: 1.38,
                    letterSpacing: -0.5,
                  ),
                  startLength: 40,
                  endLength: 40,
                  ellipsisLength: 3,
                  colorType: ColoredTextEnum.coloredIntegers,
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
