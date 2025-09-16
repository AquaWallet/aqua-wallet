import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/config/config.dart';

class ButtonLink extends StatelessWidget {
  const ButtonLink({super.key, required this.onPress, required this.text});

  final String text;
  final void Function()? onPress;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colors.onBackground,
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      onPressed: onPress,
      child: Row(
        children: [
          Text(
            text,
            style: TextStyle(
              color: Theme.of(context).colors.link,
              fontSize: 14,
            ),
          ),
          const SizedBox(
            width: 4,
          ),
          UiAssets.externalLink.svg(color: Theme.of(context).colors.link)
        ],
      ),
    );
  }
}
