import 'package:coin_cz/common/common.dart';
import 'package:coin_cz/features/shared/shared.dart';
import 'package:coin_cz/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:coin_cz/config/config.dart';

class GenericAlertSheet extends HookWidget {
  const GenericAlertSheet({
    super.key,
    required this.title,
    required this.message,
    required this.svgPath,
    this.confirmButtonLabel,
    this.cancelButtonLabel,
    this.showCancelButton = true,
    this.height,
    required this.onConfirm,
    required this.onCancel,
  });

  final String title;
  final String message;
  final String svgPath;
  final String? confirmButtonLabel;
  final String? cancelButtonLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final bool showCancelButton;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 440.0,
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          const SizedBox(height: 46.0),
          //ANCHOR - Icon
          SvgPicture.asset(
            svgPath,
            width: 60.0,
            height: 60.0,
          ),
          const SizedBox(height: 20.0),
          //ANCHOR - Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.0,
                ),
          ),
          const SizedBox(height: 8.0),
          //ANCHOR - Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colors.onBackground,
                  ),
            ),
          ),
          const Spacer(),
          //ANCHOR - Confirm Button
          AquaElevatedButton(
            child: Text(confirmButtonLabel ?? context.loc.confirm),
            onPressed: () {
              onConfirm();
              context.pop();
            },
          ),
          if (showCancelButton) ...[
            const SizedBox(height: 8.0),
            //ANCHOR - Proceed Without Export button
            AquaTextButton(
              child: Text(cancelButtonLabel ?? context.loc.cancel),
              onPressed: () {
                onCancel();
                context.pop();
              },
            ),
          ],
          const SizedBox(height: 27.0),
        ],
      ),
    );
  }
}

void showGenericAlertSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String svgPath,
  VoidCallback? onConfirm,
  VoidCallback? onCancel,
  String? confirmButtonLabel,
  String? cancelButtonLabel,
  bool showCancelButton = true,
  bool isDismissible = true,
  double? height,
}) {
  showModalBottomSheet(
    context: context,
    isDismissible: false,
    isScrollControlled: isDismissible,
    backgroundColor: context.colors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30.0),
        topRight: Radius.circular(30.0),
      ),
    ),
    builder: (_) => GenericAlertSheet(
      title: title,
      message: message,
      svgPath: svgPath,
      height: height,
      confirmButtonLabel: confirmButtonLabel,
      cancelButtonLabel: cancelButtonLabel,
      showCancelButton: showCancelButton,
      onConfirm: onConfirm ?? () {},
      onCancel: onCancel ?? () {},
    ),
  );
}
