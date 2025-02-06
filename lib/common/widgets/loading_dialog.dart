import 'package:flutter/material.dart';

void showLoadingDialog(BuildContext context, String? description) {
  showGeneralDialog(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) => PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: LoadingIndicator(
          description: description,
        ),
      ),
    ),
  );
}

class LoadingIndicator extends StatelessWidget {
  final String? description;

  const LoadingIndicator({
    super.key,
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation(
              Theme.of(context).colorScheme.primary,
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
            child: Text(
              description ?? '',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
