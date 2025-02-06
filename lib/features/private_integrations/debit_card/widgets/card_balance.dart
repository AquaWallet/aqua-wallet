import 'package:aqua/common/common.dart';
import 'package:aqua/config/colors/aqua_colors.dart';
import 'package:aqua/data/data.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class MoonCardBalance extends HookConsumerWidget {
  const MoonCardBalance({
    super.key,
    required this.balance,
  });

  final double balance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceFormatted = useMemoized(() {
      return ref
          .read(fiatProvider)
          .formattedFiat(DecimalExt.fromDouble(balance));
    });

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            context.loc.cardBalance,
            style: const TextStyle(
              height: 1,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: UiFontFamily.inter,
              color: AquaColors.dimMarble,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$$balanceFormatted',
            style: const TextStyle(
              fontSize: 30,
              color: Colors.white,
              fontFamily: UiFontFamily.inter,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
