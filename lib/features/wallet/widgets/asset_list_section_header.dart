import 'package:aqua/features/shared/shared.dart';

class AssetListSectionHeader extends StatelessWidget {
  const AssetListSectionHeader({
    super.key,
    required this.text,
    this.children = const [],
  });

  final String text;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.topLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
