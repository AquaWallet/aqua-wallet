import 'package:aqua/config/config.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class SearchView extends StatelessWidget {
  const SearchView({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController? controller;
  final Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return BoxShadowCard(
      margin: const EdgeInsets.symmetric(horizontal: 28.0),
      borderRadius: BorderRadius.circular(12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          isDense: true,
          fillColor: Theme.of(context).colors.inputBackground,
          hintText: context.loc.searchHistory,
          hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colors.addressHistoryHintTextColor,
              ),
          prefixIcon: Container(
            padding: const EdgeInsets.only(left: 18.0, right: 12.0),
            child: SvgPicture.asset(Svgs.search,
                width: 16.0,
                height: 16.0,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colors.addressHistoryHintTextColor,
                    BlendMode.srcIn)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
