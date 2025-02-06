import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:aqua/config/config.dart';

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
            padding: const EdgeInsets.only(top: 20.0),
            child: TextButton(
              onPressed: buttonAction,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colors.onBackground,
              ),
              child: Text(
                buttonTitle ?? context.loc.retry,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
