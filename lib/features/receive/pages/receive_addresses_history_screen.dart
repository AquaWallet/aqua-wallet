import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/receive_address/receive_address_provider.dart';
import 'package:aqua/data/provider/receive_address/receive_address_ui_model.dart';
import 'package:aqua/data/provider/receive_address/receive_addresses_history_arguments.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/screens/common/search_view.dart';
import 'package:aqua/utils/extensions/context_ext.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class ReceiveAddressesHistoryScreen extends HookConsumerWidget {
  static const routeName = '/receiveAddressesHistoryScreen';

  const ReceiveAddressesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final arguments =
        ModalRoute.of(context)?.settings.arguments as AddressesHistoryArguments;
    final chipsState = ref.watch(receiveAddressChipsState);
    final controller = useTextEditingController();

    return Scaffold(
      appBar: AquaAppBar(
        showBackButton: true,
        showActionButton: false,
        title: context.loc.receiveHistoryTitle,
      ),
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.only(top: 32.h),
          padding: EdgeInsets.only(top: 32.h),
          decoration: BoxDecoration(
            color: Theme.of(context).colors.addressHistoryBackgroundColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30.r),
              topRight: Radius.circular(30.r),
            ),
          ),
          child: Column(
            children: [
              //ANCHOR - Search
              SearchView(
                controller: controller,
                onChanged: (query) =>
                    ref.read(receiveAddressProvider(arguments)).search(query),
              ),
              SizedBox(height: 30.h),
              //ANCHOR - Address Type Switch
              AddressTypeTabBar(
                onTabChange: (index) {
                  controller.clear();
                  ref.read(receiveAddressProvider(arguments)).search('');
                  ref.read(receiveAddressChipsState.notifier).state = index == 0
                      ? const ReceiveAddressChipsState.used()
                      : const ReceiveAddressChipsState.all();
                },
              ),
              //ANCHOR - Address List
              chipsState == const ReceiveAddressChipsStateUsed()
                  ? UsedAddresses(arguments,
                      onItemClick: context.copyToClipboard)
                  : AllAddresses(arguments,
                      onItemClick: context.copyToClipboard),
            ],
          ),
        ),
      ),
    );
  }
}
