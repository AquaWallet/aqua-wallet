import 'package:flutter/material.dart';

class AppBarPadding extends StatelessWidget {
  const AppBarPadding({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: MediaQuery.of(context).padding.top);
  }
}
