import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';

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
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 12.h,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.r),
          ),
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2.r,
          ),
        ),
        child: Text(
          context.loc.sendAssetScreenUseAllFundsButton,
          style: Theme.of(context).textTheme.titleMedium!.copyWith(
                fontSize: 14.sp,
                color: isSelected
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onBackground,
              ),
        ),
      ),
    );
  }
}
