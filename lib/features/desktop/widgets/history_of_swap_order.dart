import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class HistoryOfSwapOrder extends HookConsumerWidget {
  const HistoryOfSwapOrder({
    required this.data,
    super.key,
  });

  final List<SwapOrderUiModel> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquaColors = context.aquaColors;
    final tl = context.loc;
    final selectedSwapOrderTab = useState(SwapOrderTabValues.send);
    final textEditingController = useTextEditingController();
    final searchQuery = useState('');

    // Filter data based on search query
    // Or just use onChange param in AquaSearchField
    final filteredData = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return data;
      }
      return data.where((item) {
        return item.title.contains(searchQuery.value) ||
            item.titleTrailing.contains(searchQuery.value) ||
            item.subtitle.contains(searchQuery.value) ||
            item.subtitleTrailing.contains(searchQuery.value);
      }).toList();
    }, [data, searchQuery.value]);

    useEffect(() {
      void onTextChanged() {
        searchQuery.value = textEditingController.text;
      }

      // Can be removed if search query should remain
      void onSelectedAddressTabChanged() {
        textEditingController.text = '';
        searchQuery.value = '';
      }

      selectedSwapOrderTab.addListener(onSelectedAddressTabChanged);

      textEditingController.addListener(onTextChanged);
      return () {
        textEditingController.removeListener(onTextChanged);
        selectedSwapOrderTab.removeListener(onSelectedAddressTabChanged);
      };
    }, [textEditingController, selectedSwapOrderTab]);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AquaTabBar(
          height: 36,
          tabs: [tl.send, tl.receive],
          onTabChanged: (index) {
            index == 0
                ? selectedSwapOrderTab.value = SwapOrderTabValues.send
                : selectedSwapOrderTab.value = SwapOrderTabValues.receive;
          },
        ),
        const SizedBox(
          height: 16.0,
        ),
        AquaSearchField(
          hint: "Search...",
          forceFocus: true,
          controller: textEditingController,
        ),
        const SizedBox(
          height: 16.0,
        ),
        Flexible(
          child: ListCard(
            maxWidth: double.maxFinite,
            items: List.generate(
              filteredData.length,
              (index) {
                final item = filteredData[index];
                return AquaListItem(
                  title: item.title,
                  subtitle: item.subtitle,
                  subtitleColor: aquaColors.textSecondary,
                  subtitleTrailingColor: aquaColors.textSecondary,
                  subtitleTrailing: item.subtitleTrailing,
                  titleTrailing: item.titleTrailing,
                  iconTrailing: AquaIcon.chevronRight(
                    color: aquaColors.textPrimary,
                    size: 18,
                  ),
                  onTap: () => SideSheet.right(
                    context: context,
                    colors: aquaColors,
                    body: const SwapOrderSideSheet(),
                  ),
                );
              },
            ),
            noItemsTitle: 'No Addresses Found',
            noItemsSubtitle: 'Your addresses will appear here',
          ),
        ),
      ],
    );
  }
}
