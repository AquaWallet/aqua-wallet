import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/receive_address/receive_address_provider.dart';
import 'package:aqua/data/provider/receive_address/receive_address_ui_model.dart';
import 'package:aqua/data/provider/receive_address/receive_addresses_history_arguments.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:flutter_svg/svg.dart';

class AllAddresses extends ConsumerWidget {
  final ReceiveAddressesHistoryArguments? arguments;

  const AllAddresses(
    this.arguments, {
    super.key,
    required this.onItemClick,
  });

  final Function(String) onItemClick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiModel = ref.watch(receiveAllAddressesUiModelProvider(arguments));
    final query = ref.watch(receiveAddressSearchQueryProvider(arguments));

    return uiModel?.maybeMap(
          orElse: () => Container(),
          allAddresses: (uiModel) {
            final filteredUiModels = uiModel.itemUiModels
                .where((e) => e.address.toLowerCase().contains(query))
                .toList();
            return Expanded(
              child: filteredUiModels.isEmpty
                  ? const AddressHistoryEmptyView()
                  : Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: ListView.separated(
                        padding:
                            EdgeInsets.only(top: 14.h, left: 28.w, right: 28.w),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredUiModels.length,
                        itemBuilder: (context, index) {
                          return ReceiveAddressesHistoryScreenAllItem(
                            itemUiModel: filteredUiModels[index],
                            onItemClick: onItemClick,
                          );
                        },
                        separatorBuilder: (_, __) => SizedBox(height: 16.h),
                      ),
                    ),
            );
          },
          loading: (_) => Padding(
            padding: EdgeInsets.only(top: 50.h),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                    Theme.of(context).colorScheme.secondaryContainer),
              ),
            ),
          ),
          error: (uiModel) => GenericErrorWidget(
            buttonAction: uiModel.buttonAction,
          ),
        ) ??
        Container();
  }
}

class ReceiveAddressesHistoryScreenAllItem extends ConsumerWidget {
  final ReceiveAllAddressItemUiModel itemUiModel;

  const ReceiveAddressesHistoryScreenAllItem({
    super.key,
    required this.itemUiModel,
    required this.onItemClick,
  });

  final Function(String) onItemClick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      elevation: 4,
      color: Theme.of(context).colors.addressHistoryItemBackground,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: () => onItemClick(itemUiModel.address),
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          height: 80.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 12.h),
          child: Center(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                //ANCHOR - Address
                Expanded(
                  child: Text(
                    itemUiModel.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                //ANCHOR - Copy Button
                Container(
                  margin: EdgeInsets.only(left: 10.w, top: 4.h),
                  child: SvgPicture.asset(Svgs.addressCopy),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
