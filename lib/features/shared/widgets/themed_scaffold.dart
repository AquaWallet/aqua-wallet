import 'package:aqua/data/data.dart';
import 'package:aqua/features/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// The project currently uses new themes on an opt-in basis, i.e. new themes are
//applied only to screens that are migrated to design revamp.

//This is wrapper component for the Scaffold widget that applies the new theme
//to the content. All revamped screens need to use this Scaffold until the
//entire app is migrated to new designs.
class DesignRevampScaffold extends HookConsumerWidget {
  const DesignRevampScaffold({
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    required this.body,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = false,
  });

  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool extendBody;
  final bool extendBodyBehindAppBar;
  final Widget body;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode =
        ref.watch(prefsProvider.select((p) => p.isDarkMode(context)));

    return Theme(
      data: isDarkMode
          ? ref.watch(newDarkThemeProvider(context))
          : ref.watch(newLightThemeProvider(context)),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: appBar,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        bottomNavigationBar: bottomNavigationBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        body: body,
      ),
    );
  }
}
