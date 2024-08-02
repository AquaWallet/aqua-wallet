import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GenericErrorWidget extends StatelessWidget {
  const GenericErrorWidget(
      {super.key,
      this.description,
      this.buttonTitle,
      required this.buttonAction});

  final String? description;
  final String? buttonTitle;
  final VoidCallback buttonAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            description ?? context.loc.unknownErrorSubtitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.h),
            child: TextButton(
              onPressed: buttonAction,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.onBackground,
              ),
              child: Text(
                buttonTitle ?? context.loc.unknownErrorButton,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
