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
      margin: EdgeInsets.symmetric(horizontal: 28.w),
      borderRadius: BorderRadius.circular(12.r),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          filled: true,
          isDense: true,
          fillColor: Theme.of(context).colors.inputBackground,
          hintText: context.loc.receiveAddressSearchHint,
          hintStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colors.addressHistoryHintTextColor,
              ),
          prefixIcon: Container(
            padding: EdgeInsets.only(left: 18.w, right: 12.w),
            child: SvgPicture.asset(Svgs.search,
                width: 16.r,
                height: 16.r,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colors.addressHistoryHintTextColor,
                    BlendMode.srcIn)),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
