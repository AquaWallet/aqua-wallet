import 'package:aqua/config/constants/constants.dart' as constants;
import 'package:flutter/material.dart';
import 'package:aqua/config/config.dart';
import 'package:flutter_svg/svg.dart';

const _socials = {
  constants.aquaWebsiteUrl: Svgs.website,
  constants.aquaTwitterUrl: Svgs.twitter,
  constants.aquaInstagramUrl: Svgs.instagram,
  constants.aquaTelegramUrl: Svgs.telegram,
};

class SettingsSocialLinks extends StatelessWidget {
  const SettingsSocialLinks({
    super.key,
    required this.onLinkClick,
  });

  final Function(String) onLinkClick;

  @override
  Widget build(BuildContext context) {
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
        itemCount: _socials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 30.0),
        itemBuilder: (context, index) => Center(
          child: InkWell(
            onTap: () => onLinkClick(_socials.keys.elementAt(index)),
            child: SvgPicture.asset(
              _socials.values.elementAt(index),
              width: 24.0,
              height: 24.0,
              colorFilter: ColorFilter.mode(
                Theme.of(context).colors.onBackground,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
