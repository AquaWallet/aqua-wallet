import 'package:aqua/features/desktop/utils/utils.dart';
import 'package:aqua/features/desktop/widgets/widgets.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ui_components/ui_components.dart';

class HistoryOfAccountAddress extends HookConsumerWidget {
  const HistoryOfAccountAddress({
    required this.data,
    super.key,
  });

  final List<({String address, int txnCount})> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aquaColors = context.aquaColors;
    // final loc = context.loc;
    final selectedAddressTab = useState(AddressTabValues.used);
    final textEditingController = useTextEditingController();
    final searchQuery = useState('');

    // Filter data based on search query
    // Or just use onChange param in AquaSearchField
    final filteredData = useMemoized(() {
      if (searchQuery.value.isEmpty) {
        return data;
      }
      return data.where((item) {
        return item.address.contains(searchQuery.value) ||
            item.txnCount.toString().contains(searchQuery.value);
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

      selectedAddressTab.addListener(onSelectedAddressTabChanged);

      textEditingController.addListener(onTextChanged);
      return () {
        textEditingController.removeListener(onTextChanged);
        selectedAddressTab.removeListener(onSelectedAddressTabChanged);
      };
    }, [textEditingController, selectedAddressTab]);

    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AquaTabBar(
          height: 36,
          tabs: const ['Used', 'Unused'],
          onTabChanged: (index) {
            index == 0
                ? selectedAddressTab.value = AddressTabValues.used
                : selectedAddressTab.value = AddressTabValues.unused;
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
                return AquaAddressItem(
                  address: item.address,
                  copyable: true,
                  colors: aquaColors,
                  onTap: (_) {},
                  txnCount: item.txnCount,
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
