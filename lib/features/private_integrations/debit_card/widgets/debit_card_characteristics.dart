import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/gen/fonts.gen.dart';
import 'package:aqua/utils/utils.dart';

class DebitCardCharacteristics extends StatelessWidget {
  const DebitCardCharacteristics({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.characteristics,
            style: TextStyle(
              fontSize: 14,
              color: context.colors.onBackground,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 21),
          _CharacteristicItem(
            label: context.loc.noPersonalDataRequired,
          ),
          const SizedBox(height: 21),
          _CharacteristicItem(
            label: context.loc.feePayments1,
          ),
          const SizedBox(height: 21),
          _CharacteristicItem(
            label: context.loc.limit4000UsdPerMonth,
          )
        ],
      ),
    );
  }
}

class _CharacteristicItem extends StatelessWidget {
  const _CharacteristicItem({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        UiAssets.svgs.debitCardCharacteristicsCheck.svg(
          width: 36,
          height: 36,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontFamily: UiFontFamily.helveticaNeue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
