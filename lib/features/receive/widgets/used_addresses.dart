import 'package:aqua/config/config.dart';
import 'package:aqua/data/provider/receive_address/receive_address_provider.dart';
import 'package:aqua/data/provider/receive_address/receive_address_ui_model.dart';
import 'package:aqua/data/provider/receive_address/receive_addresses_history_arguments.dart';
import 'package:aqua/features/receive/receive.dart';
import 'package:aqua/features/shared/shared.dart';
import 'package:aqua/utils/utils.dart';
import 'package:flutter_svg/svg.dart';

class UsedAddresses extends HookConsumerWidget {
  final ReceiveAddressesHistoryArguments? arguments;

  const UsedAddresses(
    this.arguments, {
    super.key,
    required this.onItemClick,
  });

  final Function(String) onItemClick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiModel = ref.watch(receiveAddressesUiModelProvider(arguments));
    final query = ref.watch(receiveAddressSearchQueryProvider(arguments));

    return uiModel?.maybeMap(
          orElse: () => Container(),
          usedAddresses: (uiModel) {
            final filteredUiModels = uiModel.itemUiModels
                .where((e) =>
                    e.addresses.any((a) => a.toLowerCase().contains(query)))
                .toList();
            return Expanded(
              child: filteredUiModels.isEmpty == true
                  ? const AddressHistoryEmptyView()
                  : Padding(
                      padding: EdgeInsets.only(top: 16.h),
                      child: ListView.separated(
                        padding:
                            EdgeInsets.only(top: 14.h, left: 28.w, right: 28.w),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredUiModels.length,
                        itemBuilder: (context, index) {
                          return ReceiveAddressesHistoryScreenUsedItem(
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
          error: (uiModel) {
            return GenericErrorWidget(
              buttonAction: uiModel.buttonAction,
            );
          },
        ) ??
        Container();
  }
}

class ReceiveAddressesHistoryScreenUsedItem extends StatelessWidget {
  final ReceiveUsedAddressItemUiModel itemUiModel;

  const ReceiveAddressesHistoryScreenUsedItem({
    super.key,
    required this.itemUiModel,
    required this.onItemClick,
  });

  final Function(String) onItemClick;

  @override
  Widget build(BuildContext context) {
    return BoxShadowCard(
      elevation: 4,
      color: Theme.of(context).colors.addressHistoryItemBackground,
      borderRadius: BorderRadius.circular(12.r),
      child: InkWell(
        onTap: itemUiModel.addresses.isNotEmpty
            ? () => onItemClick(itemUiModel.addresses.first)
            : null,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          height: 118.h,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 18.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    //ANCHOR - Address
                    Text(
                      itemUiModel.addresses.first,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(children: [
                          //ANCHOR - Receive Date Label
                          Text(
                            context.loc.receiveAddressHistoryReceivedLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  height: 1.3,
                                  fontSize: 13.sp,
                                ),
                          ),
                          const Spacer(),
                          //ANCHOR - Receive Amount
                          Text(
                            itemUiModel.amount,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  height: 1.3,
                                  fontSize: 13.sp,
                                ),
                          ),
                        ]),
                        Row(children: [
                          //ANCHOR - Receive Date
                          Text(
                            itemUiModel.date,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  height: 1.3,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                          const Spacer(),
                          //ANCHOR - Network
                          Text(
                            itemUiModel.network,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onBackground,
                                  height: 1.3,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w400,
                                ),
                          ),
                        ]),
                        SizedBox(height: 2.h),
                      ],
                    ),
                  ],
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
    );
  }
}
