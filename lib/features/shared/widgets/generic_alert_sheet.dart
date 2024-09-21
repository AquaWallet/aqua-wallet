import 'package:aqua/common/common.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';

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
      height: height ?? 440.h,
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          SizedBox(height: 46.h),
          //ANCHOR - Icon
          SvgPicture.asset(
            svgPath,
            width: 60.r,
            height: 60.r,
          ),
          SizedBox(height: 20.h),
          //ANCHOR - Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 20.sp,
                ),
          ),
          SizedBox(height: 8.h),
          //ANCHOR - Description
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
            ),
          ),
          const Spacer(),
          //ANCHOR - Confirm Button
          AquaElevatedButton(
            child: Text(confirmButtonLabel ?? context.loc.confirm),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
          ),
          if (showCancelButton) ...[
            SizedBox(height: 8.h),
            //ANCHOR - Proceed Without Export button
            AquaTextButton(
              child: Text(cancelButtonLabel ?? context.loc.cancel),
              onPressed: () {
                onCancel();
                Navigator.of(context).pop();
              },
            ),
          ],
          SizedBox(height: 27.h),
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
    backgroundColor: context.colorScheme.background,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(30.r),
        topRight: Radius.circular(30.r),
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
