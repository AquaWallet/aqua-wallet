import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:aqua/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:ui_components/ui_components.dart';

class SettingsSocialLinks extends StatelessWidget {
  const SettingsSocialLinks({
    super.key,
    required this.onLinkClick,
  });

  final Function(String) onLinkClick;

  @override
  Widget build(BuildContext context) {
    final socials = {
      constants.aquaWebsiteUrl: AquaIcon.web(
        size: 24,
        color: context.aquaColors.textPrimary,
      ),
      constants.aquaTwitterUrl: AquaIcon.twitter(
        size: 24,
        color: context.aquaColors.textPrimary,
      ),
      constants.aquaInstagramUrl: AquaIcon.instagram(
        size: 24,
        color: context.aquaColors.textPrimary,
      ),
      constants.aquaTelegramUrl: AquaIcon.telegram(
        size: 24,
        color: context.aquaColors.textPrimary,
      ),
    };

    return Container(
      height: 50.0,
      alignment: Alignment.center,
      margin: const EdgeInsets.only(left: 10.0, right: 8.0),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.only(right: 8.0),
        itemCount: socials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 30.0),
        itemBuilder: (context, index) => Center(
          child: InkWell(
            onTap: () => onLinkClick(socials.keys.elementAt(index)),
            child: socials.values.elementAt(index),
          ),
        ),
      ),
    );
  }
}
