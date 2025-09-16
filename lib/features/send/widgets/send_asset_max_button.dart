import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:coin_cz/config/config.dart';

class SendAssetMaxButton extends StatelessWidget {
  const SendAssetMaxButton({
    super.key,
    required this.isSelected,
    this.onPressed,
  });

  final VoidCallback? onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor:
              isSelected ? Theme.of(context).colorScheme.primary : null,
          padding: const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 12.0,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.0,
          ),
        ),
        child: Text(
          context.loc.sendAssetScreenUseAllFundsButton,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 14.0,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colors.onBackground,
              ),
        ),
      ),
    );
  }
}
