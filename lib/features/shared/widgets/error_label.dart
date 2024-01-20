import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ErrorLabel extends StatelessWidget {
  const ErrorLabel({
    Key? key,
    required this.text,
  }) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20.h,
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(
            Icons.warning_rounded,
            color: Theme.of(context).colorScheme.error,
            size: 20.r,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
