import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:ui_components/ui_components.dart';

import 'widgets.dart';

class ListCard extends StatelessWidget {
  const ListCard({
    super.key,
    required this.items,
    this.title,
    this.maxHeight,
    this.maxWidth,
    this.noItemsTitle = '',
    this.noItemsSubtitle = '',
  });

  final List<Widget> items;
  final String noItemsTitle;
  final String noItemsSubtitle;
  final String? title;
  final double? maxHeight;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: AquaText.body1SemiBold(
              text: title!,
            ),
          ),
        ],
        if (items.isEmpty) ...[
          NoDataPlaceholder(
            title: noItemsTitle,
            subtitle: noItemsSubtitle,
            aquaColors: context.aquaColors,
          )
        ] else ...[
          Expanded(
            child: OutlineContainer(
              aquaColors: context.aquaColors,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: maxHeight ?? 350.0,
                  maxWidth: maxWidth ?? 343.0,
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      StylizedDivider(
                    color: context.aquaColors.surfaceBorderPrimary,
                  ),
                  itemBuilder: (BuildContext context, int index) =>
                      items[index],
                ),
              ),
            ),
          )
        ],
      ],
    );
  }
}
