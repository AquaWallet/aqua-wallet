import 'package:aqua/common/widgets/middle_ellipsis_text.dart';
import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';

class AddressBox extends StatelessWidget {
  const AddressBox({
    super.key,
    required this.address,
  });

  final String address;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.maxFinite,
      decoration: BoxDecoration(
        color: Theme.of(context).colors.receiveAddressCopySurface,
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
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
        ],
      ),
    );
  }
}
